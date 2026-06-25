// Notification backend for the DELIVERY app (Delivery-App-Alkam).
//
// Sends Firebase Cloud Messaging push notifications to the delivery app ONLY,
// by targeting the FCM topic "Jfood". The delivery app (package
// j.food.business) subscribes to this topic in lib/main.dart, while the
// customer "jfood" app (j.food.com) subscribes to NO topic — so topic sends
// never reach the customer app.
//
// Run:
//   npm run start         (or: node server.js)
//
// Then the dashboard tab "اشعارات تطبيق التوصيل" POSTs to:
//   POST http://localhost:4000/send-delivery-notification
//   { "title": "...", "body": "..." }

const path = require('path')
const express = require('express')
const cors = require('cors')
const admin = require('firebase-admin')

const SERVICE_ACCOUNT_FILE = 'j-food-2a4d7-firebase-adminsdk-25cv5-3828437e91.json'
const DELIVERY_TOPIC = 'Jfood' // delivery app only — customer app uses tokens
const PORT = process.env.PORT || 4000

const serviceAccount = require(path.join(__dirname, SERVICE_ACCOUNT_FILE))

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) })
}

const app = express()
app.use(cors())
app.use(express.json())

app.get('/health', (_req, res) => {
  res.json({ ok: true, project: serviceAccount.project_id, topic: DELIVERY_TOPIC })
})

app.post('/send-delivery-notification', async (req, res) => {
  const title = (req.body.title || '').toString().trim()
  const body = (req.body.body || '').toString().trim()

  if (!title || !body) {
    return res.status(400).json({ ok: false, error: 'title و body مطلوبان' })
  }

  const message = {
    topic: DELIVERY_TOPIC,
    notification: { title, body },
    android: {
      priority: 'high',
      notification: { sound: 'default', channelId: 'high_importance_channel' },
    },
    apns: { payload: { aps: { sound: 'default', badge: 1 } } },
  }

  try {
    const messageId = await admin.messaging().send(message)
    console.log(`✅ Sent to topic "${DELIVERY_TOPIC}":`, messageId)
    res.json({ ok: true, messageId, topic: DELIVERY_TOPIC })
  } catch (error) {
    console.error('❌ FCM error:', error.message)
    res.status(500).json({ ok: false, error: error.message })
  }
})

app.listen(PORT, () => {
  console.log(`🚚 Delivery notification server on http://localhost:${PORT}`)
  console.log(`   Sending to topic: "${DELIVERY_TOPIC}" (delivery app only)`)
})
