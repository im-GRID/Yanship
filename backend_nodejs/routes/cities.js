// routes/cities.js
const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { authenticateToken, requireRole } = require('../src/middleware/auth');

// Récupérer toutes les villes
const getAllCities = async (req, res) => {
  try {
    const { status, limit = 100, offset = 0, search } = req.query;

    const limitInt = parseInt(limit, 10) || 100;
    const offsetInt = parseInt(offset, 10) || 0;

    let query = `
      SELECT id, name, comm, created_at, updated_at, status
      FROM cdb_cities
    `;

    let params = [];
    let conditions = [];

    if (status) {
      conditions.push('status = ?');
      params.push(status);
    }

    if (search) {
      conditions.push('(name LIKE ? OR comm LIKE ?)');
      params.push(`%${search}%`, `%${search}%`);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    query += ` ORDER BY name ASC LIMIT ${limitInt} OFFSET ${offsetInt}`;

    const [cities] = await pool.execute(query, params);

    // Count total
    let countQuery = 'SELECT COUNT(*) as total FROM cdb_cities';
    let countParams = [];
    if (conditions.length > 0) {
      countQuery += ' WHERE ' + conditions.join(' AND ');
      countParams = params;
    }
    const [countResult] = await pool.execute(countQuery, countParams);

    res.json({
      success: true,
      data: {
        cities,
        pagination: {
          total: countResult[0].total,
          limit: limitInt,
          offset: offsetInt,
          hasMore: countResult[0].total > offsetInt + cities.length
        }
      }
    });
  } catch (error) {
    console.error('Get all cities error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Récupérer une ville par ID
const getCityById = async (req, res) => {
  try {
    const { id } = req.params;

    const [cities] = await pool.execute(
      'SELECT id, name, comm, created_at, updated_at, status FROM cdb_cities WHERE id = ?',
      [id]
    );

    if (cities.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'City not found'
      });
    }

    res.json({
      success: true,
      data: {
        city: cities[0]
      }
    });
  } catch (error) {
    console.error('Get city by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Créer une nouvelle ville
const createCity = async (req, res) => {
  try {
    const { name, comm, status = 'active' } = req.body;

    // Validation des champs requis
    if (!name || name.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'City name is required'
      });
    }

    // Vérifier si la ville existe déjà
    const [existingCities] = await pool.execute(
      'SELECT id FROM cdb_cities WHERE name = ?',
      [name.trim()]
    );

    if (existingCities.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'City name already exists'
      });
    }

    // Créer la ville
    const [result] = await pool.execute(
      'INSERT INTO cdb_cities (name, comm, status, created_at, updated_at) VALUES (?, ?, ?, NOW(), NOW())',
      [name.trim(), comm || null, status]
    );

    // Récupérer la ville créée
    const [newCity] = await pool.execute(
      'SELECT id, name, comm, created_at, updated_at, status FROM cdb_cities WHERE id = ?',
      [result.insertId]
    );

    res.status(201).json({
      success: true,
      message: 'City created successfully',
      data: {
        city: newCity[0]
      }
    });
  } catch (error) {
    console.error('Create city error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Mettre à jour une ville
const updateCity = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, comm, status } = req.body;

    // Vérifier si la ville existe
    const [existingCities] = await pool.execute(
      'SELECT id, name FROM cdb_cities WHERE id = ?',
      [id]
    );

    if (existingCities.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'City not found'
      });
    }

    // Vérifier si le nouveau nom existe déjà (pour une autre ville)
    if (name && name !== existingCities[0].name) {
      const [duplicateCities] = await pool.execute(
        'SELECT id FROM cdb_cities WHERE name = ? AND id != ?',
        [name.trim(), id]
      );

      if (duplicateCities.length > 0) {
        return res.status(409).json({
          success: false,
          message: 'City name already exists'
        });
      }
    }

    // Préparer les valeurs pour la mise à jour
    const updateFields = [];
    const updateValues = [];

    if (name !== undefined) {
      updateFields.push('name = ?');
      updateValues.push(name.trim());
    }
    
    if (comm !== undefined) {
      updateFields.push('comm = ?');
      updateValues.push(comm);
    }
    
    if (status !== undefined) {
      updateFields.push('status = ?');
      updateValues.push(status);
    }

    // Ajouter la date de mise à jour
    updateFields.push('updated_at = NOW()');

    // Ajouter l'ID à la fin pour la clause WHERE
    updateValues.push(id);

    if (updateFields.length === 1) { // Seulement updated_at
      return res.status(400).json({
        success: false,
        message: 'No fields to update'
      });
    }

    const query = `UPDATE cdb_cities SET ${updateFields.join(', ')} WHERE id = ?`;

    // Mettre à jour la ville
    const [result] = await pool.execute(query, updateValues);

    // Récupérer la ville mise à jour
    const [updatedCity] = await pool.execute(
      'SELECT id, name, comm, created_at, updated_at, status FROM cdb_cities WHERE id = ?',
      [id]
    );

    res.json({
      success: true,
      message: 'City updated successfully',
      data: {
        city: updatedCity[0]
      }
    });

  } catch (error) {
    console.error('Update city error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Supprimer une ville
const deleteCity = async (req, res) => {
  try {
    const { id } = req.params;

    // Vérifier si la ville existe
    const [existingCities] = await pool.execute(
      'SELECT id FROM cdb_cities WHERE id = ?',
      [id]
    );

    if (existingCities.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'City not found'
      });
    }

    // Vérifier si la ville est utilisée dans des commandes
    const [usedInOrders] = await pool.execute(
      'SELECT COUNT(*) as count FROM cdb_add_order WHERE city = ?',
      [id]
    );

    if (usedInOrders[0].count > 0) {
      return res.status(409).json({
        success: false,
        message: 'Cannot delete city. It is being used in orders.'
      });
    }

    // Supprimer la ville
    await pool.execute('DELETE FROM cdb_cities WHERE id = ?', [id]);

    res.json({
      success: true,
      message: 'City deleted successfully'
    });

  } catch (error) {
    console.error('Delete city error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Routes
router.get('/', authenticateToken, requireRole(2), getAllCities);
router.get('/:id', authenticateToken, requireRole(2), getCityById);
router.post('/', authenticateToken, requireRole(2), createCity);
router.put('/:id', authenticateToken, requireRole(2), updateCity);
router.delete('/:id', authenticateToken, requireRole(2), deleteCity);

module.exports = router;