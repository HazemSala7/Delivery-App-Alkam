// Send a targeted push to ONE driver's personal topic (driver_<salesmanId>).
// Every device logged in with that driver's account receives it.
//
// Usage:
//   node send_test_driver.js <salesmanId> ["title"] ["body"]
//   node send_test_driver.js 8608 "طلب جديد" "طلب #101190"

const path = require('path')
const admin = require('firebase-admin')
const serviceAccount = require(path.join(
  __dirname,
  'j-food-2a4d7-firebase-adminsdk-25cv5-3828437e91.json',
))

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) })
}

const salesmanId = process.argv[2]
if (!salesmanId) {
  console.error('❌ مرّر رقم السائق: node send_test_driver.js <salesmanId>')
  process.exit(1)
}

const title = process.argv[3] || 'طلب توصيل جديد 🚚'
const body = process.argv[4] || 'لديك طلب جديد — افتح التطبيق لعرض التفاصيل.'
const topic = `driver_${salesmanId}`

const orderId = process.argv[5] || '999999'

const message = {
  topic,
  notification: { title, body },
  android: {
    priority: 'high',
    notification: {
      sound: 'order_alarm', // loud 2s alarm tone (res/raw/order_alarm.wav)
      channelId: 'new_order_alert_channel',
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
  },
  apns: {
    headers: { 'apns-priority': '10' },
    payload: { aps: { sound: 'order_alarm.wav', badge: 1 } },
  },
  // order_id so tapping the notification opens the order.
  data: { order_id: String(orderId), type: 'new_order' },
}

admin
  .messaging()
  .send(message)
  .then((id) => {
    console.log(`✅ Sent to topic "${topic}". Message ID:`, id)
    process.exit(0)
  })
  .catch((e) => {
    console.error('❌ Error:', e.errorInfo ? e.errorInfo.message : e.message)
    process.exit(1)
  })
