//--------
const pool = require('../config/db');
const whatsappService = require('../services/whatsapp.service');
const crypto = require('crypto');
const bcrypt = require('bcrypt');
// In-memory session storage (in production, use Redis or database)
const userSessions = new Map();

// In-memory token storage (stores tokens temporarily)
const loginTokens = new Map();

// Session timeout (15 minutes)
const SESSION_TIMEOUT = 15 * 60 * 1000*1000000000;

// Authentication timeout (5 minutes for login process)
const AUTH_TIMEOUT = 5 * 60 * 1000;

// Token timeout (5 minutes)
const TOKEN_TIMEOUT = 5 * 60 * 1000;

// Maximum login attempts
const MAX_LOGIN_ATTEMPTS = 3;
const LOCKOUT_DURATION = 30 * 60 * 1000; // 30 minutes lockout

// Clean up expired sessions and tokens
setInterval(() => {
  const now = Date.now();
  
  // Clean up expired sessions
  for (const [phone, session] of userSessions.entries()) {
    const timeout = session.state === 'authenticated' ? SESSION_TIMEOUT : AUTH_TIMEOUT;
    if (now - session.lastActivity > timeout) {
      userSessions.delete(phone);
    }
  }
  
  // Clean up expired tokens
  for (const [tokenKey, tokenData] of loginTokens.entries()) {
    if (now > tokenData.expiresAt) {
      loginTokens.delete(tokenKey);
    }
  }
}, 5 * 60 * 1000); // Check every 5 minutes

// Get or create user session
function getSession(phone) {
  if (!userSessions.has(phone)) {
    userSessions.set(phone, {
      state: 'unauthenticated',
      data: {},
      lastActivity: Date.now(),
      loginAttempts: 0,
      lockedUntil: null
    });
  }
  const session = userSessions.get(phone);
  session.lastActivity = Date.now();
  return session;
}

// Update session state
function updateSession(phone, state, data = {}) {
  const session = getSession(phone);
  session.state = state;
  session.data = { ...session.data, ...data };
  session.lastActivity = Date.now();
}

// Clear session
function clearSession(phone) {
  userSessions.delete(phone);
}

// Check if user is locked out
function isLockedOut(session) {
  if (!session.lockedUntil) return false;
  if (Date.now() > session.lockedUntil) {
    // Lockout period has expired
    session.lockedUntil = null;
    session.loginAttempts = 0;
    return false;
  }
  return true;
}

// Increment login attempts and lock if necessary
function handleFailedLogin(session) {
  session.loginAttempts++;
  if (session.loginAttempts >= MAX_LOGIN_ATTEMPTS) {
    session.lockedUntil = Date.now() + LOCKOUT_DURATION;
    return true; // User is now locked
  }
  return false;
}

// Generate a secure login token
function generateLoginToken() {
  return crypto.randomBytes(6).toString('hex').toUpperCase();
}

// Store login token in memory
function storeLoginToken(driverId, token) {
  try {
    const tokenKey = `${driverId}_${token}`;
    loginTokens.set(tokenKey, {
      driverId,
      token,
      expiresAt: Date.now() + TOKEN_TIMEOUT,
      used: false
    });
    return true;
  } catch (error) {
    console.error('Error storing login token:', error);
    return false;
  }
}

// Verify login token
function verifyLoginToken(driverId, token) {
  try {
    const tokenKey = `${driverId}_${token}`;
    const tokenData = loginTokens.get(tokenKey);
    
    if (!tokenData) return false;
    if (tokenData.used) return false;
    if (Date.now() > tokenData.expiresAt) return false;
    if (tokenData.driverId !== driverId) return false;
    
    // Mark token as used
    tokenData.used = true;
    
    // Clean up used token
    setTimeout(() => {
      loginTokens.delete(tokenKey);
    }, 1000);
    
    return true;
  } catch (error) {
    console.error('Error verifying login token:', error);
    return false;
  }
}

// Find driver by phone number
async function findDriverByPhone(phone) {
  try {
    // Clean phone number (remove whatsapp: prefix and normalize)
    const cleanPhone = phone.replace('whatsapp:', '').replace(/\s+/g, '').trim();
    
    console.log(`🔍 Searching for driver with phone: ${cleanPhone}`);
    
    const [drivers] = await pool.query(
      'SELECT * FROM cdb_users WHERE phone LIKE ? AND userlevel = 3 AND active = 1',
      [`%${cleanPhone}%`]
    );
    
    console.log(`📋 Found ${drivers.length} drivers matching phone ${cleanPhone}`);
    if (drivers.length > 0) {
      console.log(`✅ Driver found: ${drivers[0].fname} ${drivers[0].lname} (ID: ${drivers[0].id}, userlevel: ${drivers[0].userlevel})`);
    }
    
    return drivers.length > 0 ? drivers[0] : null;
  } catch (error) {
    console.error('Error finding driver:', error);
    return null;
  }
}

// Authenticate driver with username and password
// Authenticate driver with username/email and password (bcrypt-aware)
async function authenticateDriver(username, password) {
  try {
    console.log(`🔐 Authenticating driver (WA): ${username}`);

    // Accept username OR email for login, but ensure driver-level and active
    const [drivers] = await pool.query(
      'SELECT * FROM cdb_users WHERE (username = ? OR email = ?) AND userlevel = 3 AND active = 1',
      [username, username]
    );

    if (drivers.length === 0) {
      console.log(`❌ No active driver found (userlevel=3) with username/email: ${username}`);
      return null;
    }

    const driver = drivers[0];
    console.log(`📋 Driver found: ${driver.fname || ''} ${driver.lname || ''} (ID: ${driver.id}, userlevel: ${driver.userlevel})`);

    // Compare bcrypt hash if applicable; fall back to plain equality for legacy rows
    let isPasswordValid = false;
    try {
      if (driver.password && driver.password.startsWith('$2')) {
        isPasswordValid = await bcrypt.compare(password, driver.password);
      } else {
        isPasswordValid = password === driver.password;
      }
    } catch (cmpErr) {
      console.error('Error comparing password with bcrypt:', cmpErr);
      isPasswordValid = false;
    }

    if (!isPasswordValid) {
      console.log(`❌ Invalid password for driver: ${username}`);
      return null;
    }

    console.log(`✅ Authentication successful for driver: ${username}`);
    return driver;
  } catch (error) {
    console.error('Error authenticating driver:', error);
    return null;
  }
}

// Get driver's active orders
async function getDriverOrders(driverId) {
  try {
    const [orders] = await pool.query(`
      SELECT 
        order_id,
        order_no,
        order_prefix,
        CONCAT(IFNULL(order_prefix, ''), order_no) as order_reference,
        receiver_name,
        address,
        city,
        status_courier,
        price
      FROM cdb_add_order 
      WHERE driver_id = ? AND status_courier NOT IN (28, 29, 3, 5)
      ORDER BY order_date DESC
      LIMIT 10
    `, [driverId]);
    
    return orders;
  } catch (error) {
    console.error('Error getting driver orders:', error);
    return [];
  }
}

// Status mapping
const STATUS_MAP = {
  25: "Picked up",
  28: "Delivered",
  3: "Cancelled",
  5: "Rejected",
  26: "Reported",
  29: "No answer"
};

// ===== SYSTÈME DE TRADUCTION =====
const TRANSLATIONS = {
  fr: {
    // Messages d'authentification
    welcome: "🔐 *Authentification YanShip Livreur*\n\nBienvenue sur le Portail YanShip Livreur!\n\nPour des raisons de sécurité, vous devez vous authentifier avant d'accéder à votre compte.\n\n*1* - 🔑 Connexion avec Nom d'utilisateur et Mot de passe\n*2* - 📱 Demander un Token de Connexion\n*0* - ❌ Quitter\n\nRépondez avec votre choix.",
    loginRequired: "🔑 *Connexion Requise*\n\nVeuillez entrer vos identifiants dans ce format:\n\n*nom_utilisateur:mot_de_passe*\n\nExemple: john123:monmotdepasse\n\n*0* - ⬅️ Retour au Menu d'Authentification",
    tokenRequest: "📱 *Authentification par Token*\n\nVeuillez entrer votre nom d'utilisateur pour recevoir un token de connexion:\n\n*0* - ⬅️ Retour au Menu d'Authentification",
    tokenInput: "🔢 *Entrer le Token*\n\nVeuillez entrer le token de 12 caractères affiché ci-dessous:\n\n*0* - ⬅️ Retour au Menu d'Authentification",
    
    // Menu principal
    mainMenu: "🚚 *Portail YanShip Livreur*\n\nBonjour {name}!\n\nChoisissez une option:\n\n*1* - 🌐 Sélection de Langue\n*2* - 📦 Gérer les Commandes\n*9* - 🔓 Déconnexion\n*0* - ❌ Quitter\n\nRépondez avec le numéro de votre choix.",
    languageMenu: "🌐 *Sélection de Langue*\n\nChoisissez votre langue préférée:\n\n*1* - 🇫🇷 Français\n*2* - 🇬🇧 English\n*3* - 🇸🇦 العربية\n*0* - ⬅️ Retour au Menu Principal\n\nRépondez avec votre choix.",
    
    // Gestion des commandes
    noOrders: "📦 *Gestion des Commandes*\n\nVous n'avez aucune commande active.\n\n*0* - ⬅️ Retour au Menu Principal",
    ordersMenu: "📦 *Gestion des Commandes*\n\nVos commandes actives:\n\n{orders}\n\n*0* - ⬅️ Retour au Menu Principal\n\nSélectionnez une commande pour mettre à jour son statut.",
    orderItem: "*{index}* - Commande #{orderNo}\n   📍 {receiverName}\n   🏠 {city}\n   📊 Statut: {status}\n   💰 {price} MAD\n\n",
    
    // Mise à jour des statuts
    statusUpdateMenu: "📊 *Mettre à Jour le Statut de la Commande*\n\nCommande: #{orderNo}\nStatut Actuel: {currentStatus}\n\nChoisissez le nouveau statut:\n\n*1* - 📦 Ramassée\n*2* - ✅ Livrée\n*3* - 📝 Signalée\n*4* - 📵 Pas de réponse\n*5* - 🔄 Rejetée\n*6* - ❌ Annulée\n*0* - ⬅️ Retour aux Commandes\n\nRépondez avec votre choix.",
    
    // Messages de succès/erreur
    authSuccess: "✅ *Authentification Réussie*\n\nBienvenue, {name}!\n\n{mainMenu}",
    authFailed: "❌ *Identifiants Invalides*\n\nNom d'utilisateur ou mot de passe incorrect.\nTentatives restantes: {attempts}\n\n{loginMessage}",
    accountLocked: "🔒 *Compte Verrouillé*\n\nTrop de tentatives de connexion échouées. Votre compte est verrouillé pendant 30 minutes.",
    logoutSuccess: "🔓 *Déconnexion Réussie*\n\nVous avez été déconnecté pour des raisons de sécurité.\n\nEnvoyez \"start\" ou \"begin\" pour vous authentifier à nouveau.",
    goodbye: "👋 *Au revoir!*\n\nMerci d'avoir utilisé le Portail YanShip Livreur.\n\nEnvoyez \"start\" ou \"begin\" pour vous authentifier à nouveau.",
    invalidOption: "❌ *Option Invalide*\n\n{menu}",
    languageChanged: "🇫🇷 *Langue changée en Français*\n\nVotre langue a été changée en français.\n\n{mainMenu}",
    statusUpdated: "✅ *Statut Mis à Jour avec Succès*\n\nLe statut de la commande #{orderNo} a été changé en: *{status}*\n\n{mainMenu}",
    error: "❌ *Erreur*\n\n{message}\n\n{mainMenu}"
  },
  
  en: {
    // Authentication messages
    welcome: "🔐 *YanShip Driver Authentication*\n\nWelcome to the YanShip Driver Portal!\n\nFor security purposes, you need to authenticate before accessing your account.\n\n*1* - 🔑 Login with Username & Password\n*2* - 📱 Request Login Token\n*0* - ❌ Exit\n\nReply with your choice.",
    loginRequired: "🔑 *Login Required*\n\nPlease enter your credentials in this format:\n\n*username:password*\n\nExample: john123:mypassword\n\n*0* - ⬅️ Back to Authentication Menu",
    tokenRequest: "📱 *Token Authentication*\n\nPlease enter your username to receive a login token:\n\n*0* - ⬅️ Back to Authentication Menu",
    tokenInput: "🔢 *Enter Token*\n\nPlease enter the 12-character token shown below:\n\n*0* - ⬅️ Back to Authentication Menu",
    
    // Main menu
    mainMenu: "🚚 *YanShip Driver Portal*\n\nHello {name}!\n\nChoose an option:\n\n*1* - 🌐 Language Selection\n*2* - 📦 Manage Orders\n*9* - 🔓 Logout\n*0* - ❌ Exit\n\nReply with the number of your choice.",
    languageMenu: "🌐 *Language Selection*\n\nChoose your preferred language:\n\n*1* - 🇫🇷 Français\n*2* - 🇬🇧 English\n*3* - 🇸🇦 العربية\n*0* - ⬅️ Back to Main Menu\n\nReply with your choice.",
    
    // Order management
    noOrders: "📦 *Order Management*\n\nYou have no active orders.\n\n*0* - ⬅️ Back to Main Menu",
    ordersMenu: "📦 *Order Management*\n\nYour active orders:\n\n{orders}\n\n*0* - ⬅️ Back to Main Menu\n\nSelect an order to update its status.",
    orderItem: "*{index}* - Order #{orderNo}\n   📍 {receiverName}\n   🏠 {city}\n   📊 Status: {status}\n   💰 {price} MAD\n\n",
    
    // Status updates
    statusUpdateMenu: "📊 *Update Order Status*\n\nOrder: #{orderNo}\nCurrent Status: {currentStatus}\n\nChoose new status:\n\n*1* - 📦 Picked up\n*2* - ✅ Delivered\n*3* - 📝 Reported\n*4* - 📵 No answer\n*5* - 🔄 Rejected\n*6* - ❌ Cancelled\n*0* - ⬅️ Back to Orders\n\nReply with your choice.",
    
    // Success/error messages
    authSuccess: "✅ *Authentication Successful*\n\nWelcome, {name}!\n\n{mainMenu}",
    authFailed: "❌ *Invalid Credentials*\n\nIncorrect username or password.\nAttempts remaining: {attempts}\n\n{loginMessage}",
    accountLocked: "🔒 *Account Locked*\n\nToo many failed login attempts. Your account is locked for 30 minutes.",
    logoutSuccess: "🔓 *Logged Out Successfully*\n\nYou have been logged out for security.\n\nSend \"start\" or \"begin\" to authenticate again.",
    goodbye: "👋 *Goodbye!*\n\nThank you for using YanShip Driver Portal.\n\nSend \"start\" or \"begin\" to authenticate again.",
    invalidOption: "❌ *Invalid Option*\n\n{menu}",
    languageChanged: "🇬🇧 *Language changed to English*\n\nYour language has been changed to English.\n\n{mainMenu}",
    statusUpdated: "✅ *Status Updated Successfully*\n\nOrder #{orderNo} status changed to: *{status}*\n\n{mainMenu}",
    error: "❌ *Error*\n\n{message}\n\n{mainMenu}"
  },
  
  ar: {
    // رسائل المصادقة
    welcome: "🔐 *مصادقة YanShip للسائقين*\n\nمرحباً بك في بوابة YanShip للسائقين!\n\nلأسباب أمنية، تحتاج إلى المصادقة قبل الوصول إلى حسابك.\n\n*1* - 🔑 تسجيل الدخول باسم المستخدم وكلمة المرور\n*2* - 📱 طلب رمز تسجيل الدخول\n*0* - ❌ خروج\n\nأجب برقم اختيارك.",
    loginRequired: "🔑 *تسجيل الدخول مطلوب*\n\nيرجى إدخال بيانات الاعتماد الخاصة بك بهذا التنسيق:\n\n*اسم_المستخدم:كلمة_المرور*\n\nمثال: john123:كلمتي\n\n*0* - ⬅️ العودة إلى قائمة المصادقة",
    tokenRequest: "📱 *مصادقة الرمز*\n\nيرجى إدخال اسم المستخدم الخاص بك لتلقي رمز تسجيل الدخول:\n\n*0* - ⬅️ العودة إلى قائمة المصادقة",
    tokenInput: "🔢 *أدخل الرمز*\n\nيرجى إدخال الرمز المكون من 12 حرفاً الموضح أدناه:\n\n*0* - ⬅️ العودة إلى قائمة المصادقة",
    
    // القائمة الرئيسية
    mainMenu: "🚚 *بوابة YanShip للسائقين*\n\nمرحباً {name}!\n\nاختر خياراً:\n\n*1* - 🌐 اختيار اللغة\n*2* - 📦 إدارة الطلبات\n*9* - 🔓 تسجيل الخروج\n*0* - ❌ خروج\n\nأجب برقم اختيارك.",
    languageMenu: "🌐 *اختيار اللغة*\n\nاختر لغتك المفضلة:\n\n*1* - 🇫🇷 Français\n*2* - 🇬🇧 English\n*3* - 🇸🇦 العربية\n*0* - ⬅️ العودة إلى القائمة الرئيسية\n\nأجب برقم اختيارك.",
    
    // إدارة الطلبات
    noOrders: "📦 *إدارة الطلبات*\n\nليس لديك طلبات نشطة.\n\n*0* - ⬅️ العودة إلى القائمة الرئيسية",
    ordersMenu: "📦 *إدارة الطلبات*\n\nطلباتك النشطة:\n\n{orders}\n\n*0* - ⬅️ العودة إلى القائمة الرئيسية\n\nاختر طلباً لتحديث حالته.",
    orderItem: "*{index}* - الطلب #{orderNo}\n   📍 {receiverName}\n   🏠 {city}\n   📊 الحالة: {status}\n   💰 {price} درهم\n\n",
    
    // تحديث الحالات
    statusUpdateMenu: "📊 *تحديث حالة الطلب*\n\nالطلب: #{orderNo}\nالحالة الحالية: {currentStatus}\n\nاختر الحالة الجديدة:\n\n*1* - 📦 تم الاستلام\n*2* - ✅ تم التسليم\n*3* - 📝 تم التبليغ\n*4* - 📵 لا يوجد رد\n*5* - 🔄 تم الرفض\n*6* - ❌ تم الإلغاء\n*0* - ⬅️ العودة إلى الطلبات\n\nأجب برقم اختيارك.",
    
    // رسائل النجاح/الخطأ
    authSuccess: "✅ *تمت المصادقة بنجاح*\n\nمرحباً {name}!\n\n{mainMenu}",
    authFailed: "❌ *بيانات اعتماد غير صحيحة*\n\nاسم المستخدم أو كلمة المرور غير صحيحة.\nالمحاولات المتبقية: {attempts}\n\n{loginMessage}",
    accountLocked: "🔒 *الحساب مقفل*\n\nالكثير من محاولات تسجيل الدخول الفاشلة. حسابك مقفل لمدة 30 دقيقة.",
    logoutSuccess: "🔓 *تم تسجيل الخروج بنجاح*\n\nتم تسجيل خروجك لأسباب أمنية.\n\nأرسل \"start\" أو \"begin\" للمصادقة مرة أخرى.",
    goodbye: "👋 *وداعاً!*\n\nشكراً لك لاستخدام بوابة YanShip للسائقين.\n\nأرسل \"start\" ou \"begin\" للمصادقة مرة أخرى.",
    invalidOption: "❌ *خيار غير صحيح*\n\n{menu}",
    languageChanged: "🇸🇦 *تم تغيير اللغة إلى العربية*\n\nتم تغيير لغتك إلى العربية.\n\n{mainMenu}",
    statusUpdated: "✅ *تم تحديث الحالة بنجاح*\n\nتم تغيير حالة الطلب #{orderNo} إلى: *{status}*\n\n{mainMenu}",
    error: "❌ *خطأ*\n\n{message}\n\n{mainMenu}"
  }
};

// Fonction de traduction principale
function translate(key, language = 'en', params = {}) {
  const lang = language || 'en';
  let message = TRANSLATIONS[lang]?.[key] || TRANSLATIONS['en'][key] || key;
  
  // Remplacer les paramètres dans le message
  Object.keys(params).forEach(param => {
    message = message.replace(new RegExp(`{${param}}`, 'g'), params[param]);
  });
  
  return message;
}

// Fonction pour obtenir la langue de la session
function getSessionLanguage(session) {
  return session?.data?.language || 'en';
}

const STATUS_OPTIONS = {
  '1': { id: 25, name: 'Picked up' },
  '2': { id: 28, name: 'Delivered' },
  '3': { id: 3, name: 'Cancelled' },
  '4': { id: 5, name: 'Rejected' },
  '5': { id: 26, name: 'Reported' },
  '6': { id: 29, name: 'No answer' }
};

// Authentication messages
function getWelcomeMessage(language = 'en') {
  return translate('welcome', language);
}

function getLoginMessage(language = 'en') {
  return translate('loginRequired', language);
}

function getTokenRequestMessage(language = 'en') {
  return translate('tokenRequest', language);
}

function getTokenInputMessage(language = 'en') {
  return translate('tokenInput', language);
}

// Main menu message
function getMainMenuMessage(driverName, language = 'en') {
  return translate('mainMenu', language, { name: driverName });
}

// Language selection menu
function getLanguageMenu(language = 'en') {
  return translate('languageMenu', language);
}

// Orders menu
function getOrdersMenuMessage(orders, language = 'en') {
  if (orders.length === 0) {
    return translate('noOrders', language);
  }
  
  let ordersList = '';
  orders.forEach((order, index) => {
    const statusName = STATUS_MAP[order.status_courier] || 'Unknown';
    const orderReference = (order.order_prefix || '') + (order.order_no || '');
    ordersList += translate('orderItem', language, {
      index: index + 1,
      orderNo: orderReference,
      receiverName: order.receiver_name,
      city: order.city,
      status: statusName,
      price: order.price
    });
  });
  
  return translate('ordersMenu', language, { orders: ordersList });
}

// Status update menu
function getStatusUpdateMenu(order, language = 'en') {
  const currentStatus = STATUS_MAP[order.status_courier] || 'Unknown';
  const orderReference = (order.order_prefix || '') + (order.order_no || '');
  return translate('statusUpdateMenu', language, {
    orderNo: orderReference,
    currentStatus: currentStatus
  });
}

// Handle incoming WhatsApp messages
exports.handleIncomingMessage = async (req, res) => {
  try {
    // Parse the raw body if it's a buffer
    let body = req.body;
    if (Buffer.isBuffer(req.body)) {
      body = JSON.parse(req.body.toString());
    }

    const From = body.From || body.from;
    const Body = body.Body || body.body;
    
    console.log('Received webhook payload:', body);
    
    if (!From || !Body) {
      console.error('Missing required fields in webhook:', body);
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    console.log(`Processing message from ${From}: ${Body}`);
    
    // Find driver by phone first
    const driver = await findDriverByPhone(From);
    if (!driver) {
      await whatsappService.sendMessage(From, 
        '❌ *Access Denied*\n\nYour phone number is not registered as a driver in our system.\n\nPlease contact support for assistance.');
      return res.status(200).json({ success: true });
    }
    
    // Get user session
    const session = getSession(From);
    const message = Body.trim().toLowerCase();
    
    // Check if user is locked out
    if (isLockedOut(session)) {
      const remainingTime = Math.ceil((session.lockedUntil - Date.now()) / 1000 / 60);
      await whatsappService.sendMessage(From, 
        `🔒 *Account Locked*\n\nToo many failed login attempts. Please try again in ${remainingTime} minutes.`);
      return res.status(200).json({ success: true });
    }
    
    let responseMessage = '';
    
    // Handle language selection when user types "start"
    if (message === 'start' || message === 'begin') {
      updateSession(From, 'language_selection');
      responseMessage = getLanguageMenu('en'); // Default to English for language selection
    }
    // Handle authentication flow
    else if (session.state === 'unauthenticated') {
      updateSession(From, 'auth_menu');
      responseMessage = getWelcomeMessage(session.data.language || 'en');
    } else if (session.state === 'authenticated') {
      // User is authenticated, handle normal flow
      responseMessage = await handleAuthenticatedUser(From, message, driver, session);
    } else {
      // Handle authentication states including language selection
      responseMessage = await handleAuthenticationFlow(From, message, driver, session);
    }
    
    if (responseMessage) {
      await whatsappService.sendMessage(From, responseMessage);
    }
    
    res.status(200).json({ success: true });
    
  } catch (error) {
    console.error('Error handling WhatsApp message:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Handle authentication flow (updated to include language_selection)
async function handleAuthenticationFlow(phone, message, driver, session) {
  const language = getSessionLanguage(session);
  
  switch (session.state) {
    case 'language_selection':
      return await handleLanguageSelection(phone, message, driver);
      
    case 'auth_menu':
      return await handleAuthMenu(phone, message, language);
      
    case 'login_prompt':
      return await handleLoginPrompt(phone, message, driver, language);
      
    case 'token_request':
      return await handleTokenRequest(phone, message, driver, language);
      
    case 'token_input':
      return await handleTokenInput(phone, message, driver, language);
      
    default:
      updateSession(phone, 'auth_menu');
      return getWelcomeMessage(language);
  }
}

// New function to handle language selection at the beginning
async function handleLanguageSelection(phone, message, driver) {
  const session = getSession(phone);
  
  switch (message) {
    case '1':
      // French
      updateSession(phone, 'auth_menu', { language: 'fr' });
      return getWelcomeMessage('fr');
      
    case '2':
      // English
      updateSession(phone, 'auth_menu', { language: 'en' });
      return getWelcomeMessage('en');
      
    case '3':
      // Arabic
      updateSession(phone, 'auth_menu', { language: 'ar' });
      return getWelcomeMessage('ar');
      
    default:
      return translate('invalidOption', 'en', { 
        menu: getLanguageMenu('en') 
      });
  }
}

// Handle authentication menu
async function handleAuthMenu(phone, message, language = 'en') {
  switch (message) {
    case '1':
      updateSession(phone, 'login_prompt');
      return getLoginMessage(language);
      
    case '2':
      updateSession(phone, 'token_request');
      return getTokenRequestMessage(language);
      
    case '0':
      clearSession(phone);
      return translate('goodbye', language);
      
    default:
      return translate('invalidOption', language, { 
        menu: getWelcomeMessage(language) 
      });
  }
}

// Handle login with username:password
async function handleLoginPrompt(phone, message, phoneDriver, language = 'en') {
  if (message === '0') {
    updateSession(phone, 'auth_menu');
    return getWelcomeMessage(language);
  }
  
  const session = getSession(phone);
  
  // Check for username:password format
  if (!message.includes(':')) {
    return translate('invalidOption', language, { 
      menu: getLoginMessage(language) 
    });
  }
  
  const [username, password] = message.split(':', 2);
  
  if (!username || !password) {
    return translate('invalidOption', language, { 
      menu: getLoginMessage(language) 
    });
  }
  
  // Authenticate driver
  const authenticatedDriver = await authenticateDriver(username.trim(), password.trim());
  
  if (!authenticatedDriver) {
    const isLocked = handleFailedLogin(session);
    if (isLocked) {
      return translate('accountLocked', language);
    }
    const attemptsLeft = MAX_LOGIN_ATTEMPTS - session.loginAttempts;
    return translate('authFailed', language, {
      attempts: attemptsLeft,
      loginMessage: getLoginMessage(language)
    });
  }
  
  // Check if the authenticated driver matches the phone number
  if (authenticatedDriver.id !== phoneDriver.id) {
    const isLocked = handleFailedLogin(session);
    if (isLocked) {
      return translate('accountLocked', language);
    }
    return translate('authFailed', language, {
      attempts: MAX_LOGIN_ATTEMPTS - session.loginAttempts,
      loginMessage: getLoginMessage(language)
    });
  }
  
  // Successful authentication
  session.loginAttempts = 0;
  session.lockedUntil = null;
  updateSession(phone, 'authenticated', { driver: authenticatedDriver });
  
  return translate('authSuccess', language, {
    name: authenticatedDriver.fname || authenticatedDriver.username,
    mainMenu: getMainMenuMessage(authenticatedDriver.fname || authenticatedDriver.username, language)
  });
}

// Handle token request
async function handleTokenRequest(phone, message, driver, language = 'en') {
  if (message === '0') {
    updateSession(phone, 'auth_menu');
    return getWelcomeMessage(language);
  }
  
  const username = message.trim();
  
  // Verify username belongs to the phone number's driver
  if (username !== driver.username) {
    const session = getSession(phone);
    const isLocked = handleFailedLogin(session);
    if (isLocked) {
      return translate('accountLocked', language);
    }
    return translate('invalidOption', language, { 
      menu: getTokenRequestMessage(language) 
    });
  }
  
  // Generate and store login token
  const token = generateLoginToken();
  const tokenStored = storeLoginToken(driver.id, token);
  
  if (!tokenStored) {
    return translate('error', language, {
      message: 'Failed to generate login token. Please try again.',
      mainMenu: getTokenRequestMessage(language)
    });
  }
  
  // Show token in message (in production, send via SMS/Email)
  updateSession(phone, 'token_input', { expectedToken: token });
  
  return `📱 *Token Generated*\n\nYour login token is: *${token}*\n\n⏰ This token expires in 5 minutes.\n\n${getTokenInputMessage(language)}`;
}

// Handle token input
async function handleTokenInput(phone, message, driver, language = 'en') {
  if (message === '0') {
    updateSession(phone, 'auth_menu');
    return getWelcomeMessage(language);
  }
  
  const token = message.trim().toUpperCase();
  const session = getSession(phone);
  
  if (token.length !== 12) {
    return translate('invalidOption', language, { 
      menu: getTokenInputMessage(language) 
    });
  }
  
  // Verify token
  const isValidToken = verifyLoginToken(driver.id, token);
  
  if (!isValidToken) {
    const isLocked = handleFailedLogin(session);
    if (isLocked) {
      return translate('accountLocked', language);
    }
    const attemptsLeft = MAX_LOGIN_ATTEMPTS - session.loginAttempts;
    return translate('authFailed', language, {
      attempts: attemptsLeft,
      loginMessage: getTokenInputMessage(language)
    });
  }
  
  // Successful authentication
  session.loginAttempts = 0;
  session.lockedUntil = null;
  updateSession(phone, 'authenticated', { driver });
  
  return translate('authSuccess', language, {
    name: driver.fname || driver.username,
    mainMenu: getMainMenuMessage(driver.fname || driver.username, language)
  });
}

// Handle authenticated user interactions
async function handleAuthenticatedUser(phone, message, driver, session) {
  switch (session.state) {
    case 'authenticated':
      return await handleMainMenu(phone, message, driver);
      
    case 'language_menu':
      return await handleLanguageMenu(phone, message, driver);
      
    case 'orders_menu':
      return await handleOrdersMenu(phone, message, driver);
      
    case 'status_update_menu':
      return await handleStatusUpdate(phone, message, driver);
      
    default:
      updateSession(phone, 'authenticated');
      return getMainMenuMessage(driver.fname || driver.username);
  }
}

// Handle main menu selection
async function handleMainMenu(phone, message, driver) {
  const session = getSession(phone);
  const language = getSessionLanguage(session);
  
  switch (message) {
    case '1':
      updateSession(phone, 'language_menu');
      return getLanguageMenu(language);
      
    case '2':
      const orders = await getDriverOrders(driver.id);
      updateSession(phone, 'orders_menu', { orders });
      return getOrdersMenuMessage(orders, language);
      
    case '9':
      clearSession(phone);
      return translate('logoutSuccess', language);
      
    case '0':
      clearSession(phone);
      return translate('goodbye', language);
      
    default:
      return translate('invalidOption', language, { 
        menu: getMainMenuMessage(driver.fname || driver.username, language) 
      });
  }
}

// Handle language selection menu
async function handleLanguageMenu(phone, message, driver) {
  const session = getSession(phone);
  const currentLang = getSessionLanguage(session);
  
  switch (message) {
    case '1':
      // French
      updateSession(phone, 'authenticated', { language: 'fr' });
      return translate('languageChanged', 'fr', { 
        mainMenu: getMainMenuMessage(driver.fname || driver.username, 'fr') 
      });
      
    case '2':
      // English
      updateSession(phone, 'authenticated', { language: 'en' });
      return translate('languageChanged', 'en', { 
        mainMenu: getMainMenuMessage(driver.fname || driver.username, 'en') 
      });
      
    case '3':
      // Arabic
      updateSession(phone, 'authenticated', { language: 'ar' });
      return translate('languageChanged', 'ar', { 
        mainMenu: getMainMenuMessage(driver.fname || driver.username, 'ar') 
      });
      
    case '0':
      updateSession(phone, 'authenticated');
      return getMainMenuMessage(driver.fname || driver.username, currentLang);
      
    default:
      return translate('invalidOption', currentLang, { 
        menu: getLanguageMenu(currentLang) 
      });
  }
}

// Handle orders menu
async function handleOrdersMenu(phone, message, driver) {
  const session = getSession(phone);
  const orders = session.data.orders || [];
  const language = getSessionLanguage(session);
  
  if (message === '0') {
    updateSession(phone, 'authenticated');
    return getMainMenuMessage(driver.fname || driver.username, language);
  }
  
  const orderIndex = parseInt(message) - 1;
  if (orderIndex >= 0 && orderIndex < orders.length) {
    const selectedOrder = orders[orderIndex];
    updateSession(phone, 'status_update_menu', { selectedOrder });
    return getStatusUpdateMenu(selectedOrder, language);
  }
  
  return translate('invalidOption', language, { 
    menu: getOrdersMenuMessage(orders, language) 
  });
}

// Handle status update
async function handleStatusUpdate(phone, message, driver) {
  const session = getSession(phone);
  const language = getSessionLanguage(session);
  
  // Vérifier si la commande sélectionnée existe
  if (!session.data.selectedOrder) {
    console.error('Aucune commande sélectionnée pour la mise à jour');
    const orders = await getDriverOrders(driver.id);
    updateSession(phone, 'orders_menu', { driver, orders, language });
    return translate('error', language, {
      message: 'Aucune commande sélectionnée',
      menu: getOrdersMenuMessage(orders, language)
    });
  }

  const selectedOrder = session.data.selectedOrder;
  
  if (message === '0') {
    const orders = await getDriverOrders(driver.id);
    updateSession(phone, 'orders_menu', { driver, orders, language });
    return getOrdersMenuMessage(orders, language);
  }
  
  const statusOption = STATUS_OPTIONS[message];
  if (!statusOption) {
    return translate('invalidOption', language, { 
      menu: getStatusUpdateMenu(selectedOrder, language) 
    });
  }
  
  try {
    // Mise à jour du statut dans la base de données
    await pool.query(
      'UPDATE cdb_add_order SET status_courier = ? WHERE order_id = ?',
      [statusOption.id, selectedOrder.order_id]
    );
    
    // Ajout d'une entrée de suivi
    const orderTrack = selectedOrder.order_no;
    await pool.query(
      'INSERT INTO cdb_courier_track (order_track, comments, t_date, status_courier, user_id) VALUES (?, ?, NOW(), ?, ?)',
      [orderTrack, `Status updated via WhatsApp to: ${statusOption.name}`, statusOption.id, driver.id]
    );
    
    // Mise à jour de la session avec le driver et la langue
    updateSession(phone, 'authenticated', { driver, language });
    
    // Récupérer les commandes mises à jour
    const orders = await getDriverOrders(driver.id);
    
    return translate('statusUpdated', language, {
      orderNo: selectedOrder.order_no,
      status: statusOption.name,
      mainMenu: getMainMenuMessage(driver.fname || driver.username, language)
    });
    
  } catch (error) {
    console.error('Erreur lors de la mise à jour du statut:', error);
    // Réinitialiser à l'état authentifié en cas d'erreur
    updateSession(phone, 'authenticated', { driver, language });
    
    return translate('error', language, {
      message: 'Échec de la mise à jour du statut. Veuillez réessayer.',
      mainMenu: getMainMenuMessage(driver.fname || driver.username, language)
    });
  }
}

// Test endpoint to send a welcome message (now requires authentication)
exports.sendWelcomeMessage = async (req, res) => {
  try {
    const { phone } = req.body;
    
    if (!phone) {
      return res.status(400).json({ error: 'Phone number is required' });
    }
    
    const driver = await findDriverByPhone(phone);
    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }
    
    const welcomeMessage = getWelcomeMessage();
    
    const result = await whatsappService.sendMessage(phone, welcomeMessage);
    
    res.json({ success: true, result });
    
  } catch (error) {
    console.error('Error sending welcome message:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Admin endpoint to force logout a driver
exports.forceLogout = async (req, res) => {
  try {
    const { phone } = req.body;
    
    if (!phone) {
      return res.status(400).json({ error: 'Phone number is required' });
    }
    
    clearSession(phone);
    
    await whatsappService.sendMessage(phone, 
      '🔓 *Session Terminated*\n\nYour session has been terminated by an administrator.\n\nSend "start" or "begin" to authenticate again.');
    
    res.json({ success: true, message: 'Driver logged out successfully' });
    
  } catch (error) {
    console.error('Error forcing logout:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Admin endpoint to unlock a locked driver
exports.unlockDriver = async (req, res) => {
  try {
    const { phone } = req.body;
    
    if (!phone) {
      return res.status(400).json({ error: 'Phone number is required' });
    }
    
    const session = getSession(phone);
    session.lockedUntil = null;
    session.loginAttempts = 0;
    
    res.json({ success: true, message: 'Driver unlocked successfully' });
    
  } catch (error) {
    console.error('Error unlocking driver:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get session status (for debugging/admin purposes)
exports.getSessionStatus = async (req, res) => {
  try {
    const { phone } = req.query;
    
    if (!phone) {
      return res.status(400).json({ error: 'Phone number is required' });
    }
    
    const session = userSessions.get(phone);
    
    if (!session) {
      return res.json({ 
        hasSession: false, 
        message: 'No active session' 
      });
    }
    
    const isLocked = isLockedOut(session);
    const timeRemaining = session.state === 'authenticated' 
      ? Math.max(0, SESSION_TIMEOUT - (Date.now() - session.lastActivity))
      : Math.max(0, AUTH_TIMEOUT - (Date.now() - session.lastActivity));
    
    res.json({
      hasSession: true,
      state: session.state,
      isLocked,
      loginAttempts: session.loginAttempts,
      timeRemainingMs: timeRemaining,
      lastActivity: new Date(session.lastActivity).toISOString()
    });
    
  } catch (error) {
    console.error('Error getting session status:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Clean up all expired sessions manually (admin endpoint)
exports.cleanupSessions = async (req, res) => {
  try {
    const now = Date.now();
    let cleanedSessions = 0;
    let cleanedTokens = 0;
    
    // Clean up expired sessions
    for (const [phone, session] of userSessions.entries()) {
      const timeout = session.state === 'authenticated' ? SESSION_TIMEOUT : AUTH_TIMEOUT;
      if (now - session.lastActivity > timeout) {
        userSessions.delete(phone);
        cleanedSessions++;
      }
    }
    
    // Clean up expired tokens
    for (const [tokenKey, tokenData] of loginTokens.entries()) {
      if (now > tokenData.expiresAt || tokenData.used) {
        loginTokens.delete(tokenKey);
        cleanedTokens++;
      }
    }
    
    res.json({
      success: true,
      message: `Cleanup completed: ${cleanedSessions} sessions, ${cleanedTokens} tokens`
    });
    
  } catch (error) {
    console.error('Error cleaning up sessions:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get system statistics (admin endpoint)
exports.getSystemStats = async (req, res) => {
  try {
    const activeSessions = userSessions.size;
    const authenticatedSessions = Array.from(userSessions.values())
      .filter(session => session.state === 'authenticated').length;
    const lockedSessions = Array.from(userSessions.values())
      .filter(session => isLockedOut(session)).length;
    const activeTokens = loginTokens.size;
    
    res.json({
      activeSessions,
      authenticatedSessions,
      lockedSessions,
      activeTokens,
      sessionTimeout: SESSION_TIMEOUT / 1000 / 60, // in minutes
      authTimeout: AUTH_TIMEOUT / 1000 / 60, // in minutes
      maxLoginAttempts: MAX_LOGIN_ATTEMPTS,
      lockoutDuration: LOCKOUT_DURATION / 1000 / 60 // in minutes
    });
    
  } catch (error) {
    console.error('Error getting system stats:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};