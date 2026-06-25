// Quick test: send a push notification to the DELIVERY app only (topic "Jfood").
// The customer "jfood" app (j.food.com) does NOT subscribe to any topic, so it
// is never affected by topic sends.
//
// Usage:
//   node send_test.js
//   node send_test.js "Custom title" "Custom body"

const path = require('path')
const admin = require('firebase-admin')
const serviceAccount = require(path.join(
  __dirname,
  'j-food-2a4d7-firebase-adminsdk-25cv5-3828437e91.json',
))

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) })
}

const title = process.argv[2] || 'طلب توصيل جديد 🚚'
const body =
  process.argv[3] || 'هذا إشعار تجريبي من لوحة التحكم لتطبيق التوصيل.'

const message = {
  topic: 'Jfood',
  notification: { title, body },
  android: {
    priority: 'high',
    notification: { sound: 'default', channelId: 'high_importance_channel' },
  },
  apns: {
    payload: { aps: { sound: 'default', badge: 1 } },
  },
}

admin
  .messaging()
  .send(message)
  .then((response) => {
    console.log('✅ Successfully sent. Message ID:', response)
    process.exit(0)
  })
  .catch((error) => {
    console.error('❌ Error sending message:', error)
    process.exit(1)
  })
