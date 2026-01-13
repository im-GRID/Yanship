# Projet Flutter + Node.js + Firebase 
Les commandes : 

<<<<<<< HEAD
git clone -b merged-branch --single-branch https://github.com/elkadn/YanshipProject.git
=======
git clone -b mergedè-branch --single-branch https://github.com/elkadn/YanshipProject.git
>>>>>>> ea7aac586f01e26cdef278fa6853d3c9876f8a99
cd YanshipProject


# Flutter Dependencies 

cd flutter-app
flutter pub get


# Node JS Dependencies

cd backend-nodejs
npm install


# Note
+Grid et Ilyass ont une classe avec le même nom dans le projet flutter, pour cela le fichier user.dart de Ilyass a été renommé en userIlyass.dart


# Config 

+Ayoub a écrit le code API avec la syntaxe e6 et Adnane et Ilyass avec la syntaxe commonJS pour assurer les deux sur le même projet 
    +Adnane et Ilyass : node index.js (port 3000)
    +Grid : node src/server.js (port 3001)

+N'oublier pas de modifier les infos de la base de données que j'ai changé (fichier backend-nodejs/config/db.js et src/config/databases.js) 

+Ajouter un fichier .env dans la racine de backend-node.js contenant au moins les deux variables suivantes pour assurer le fonctionnement de JWT: 
    JWT_SECRET=maSuperCleSecrete123
    JWT_REFRESH_SECRET=maCleDeRefresh456

# DB modifs 
Added  push_enabled in cdb_users /   is_read in cdb_notifications  /  
a new table 'cdb_cities (	
id
name
comm
created_at
updated_at
status 
user_id
)




