const admin = require('firebase-admin');
const serviceAccount = require('C:/Users/HP/Documents/Delivery-App-Alkam/j-food-2a4d7-firebase-adminsdk-25cv5-5ace30e69d.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Example: Send a message to a topic
const message = {
  notification: {
    title: 'Hello',
    body: 'This is a notification sent using Firebase Admin SDK.'
  },
  topic: 'Jfood'
};

admin.messaging().send(message)
  .then((response) => {
    console.log('Successfully sent message:', response);
  })
  .catch((error) => {
    console.log('Error sending message:', error);
  });
