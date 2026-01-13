const twilio = require('twilio');
require('dotenv').config();

class WhatsAppService {
  constructor() {
    this.client = twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );
    this.fromNumber = process.env.TWILIO_WHATSAPP_NUMBER;
    
    // Debug: Log configuration on startup
    console.log('WhatsApp Service initialized:');
    console.log('Account SID:', process.env.TWILIO_ACCOUNT_SID ? 'Set' : 'Missing');
    console.log('Auth Token:', process.env.TWILIO_AUTH_TOKEN ? 'Set' : 'Missing');
    console.log('WhatsApp Number:', this.fromNumber);
  }

  async sendMessage(to, message) {
    try {
      console.log('=== Sending WhatsApp Message ===');
      console.log('From:', `whatsapp:${this.fromNumber}`);
      console.log('To:', `whatsapp:${to}`);
      console.log('Message:', message);
      console.log('Raw phone number:', to);
      
      // Clean and validate phone number format
      const cleanPhone = to.replace('whatsapp:', '').replace(/\s+/g, '').trim();
      if (!cleanPhone || !cleanPhone.startsWith('+')) {
        throw new Error(`Invalid phone number format: ${to}. Must start with + and country code`);
      }
      to = cleanPhone;

      const result = await this.client.messages.create({
        from: `whatsapp:${this.fromNumber}`,
        to: `whatsapp:${to}`,
        body: message
      });

      console.log('✅ WhatsApp message sent successfully:');
      console.log('Message SID:', result.sid);
      console.log('Status:', result.status);
      console.log('Error Code:', result.errorCode);
      console.log('Error Message:', result.errorMessage);
      
      return { success: true, sid: result.sid, status: result.status };
    } catch (error) {
      console.error('❌ WhatsApp sending error:');
      console.error('Error Code:', error.code);
      console.error('Error Message:', error.message);
      console.error('More Info:', error.moreInfo);
      console.error('Status:', error.status);
      console.error('Full Error:', error);
      
      return {
        success: false,
        error: error.message,
        code: error.code,
        status: error.status
      };
    }
  }

  async sendOrderUpdate(driverPhone, orderDetails) {
    console.log('=== Preparing Order Update ===');
    console.log('Driver Phone:', driverPhone);
    console.log('Order Details:', orderDetails);
    
    const message = `🚚 Order Update\n\n` +
      `Order: ${orderDetails.order_no}\n` +
      `Status: ${orderDetails.status_name}\n` +
      `Client: ${orderDetails.receiver_name}\n` +
      `Address: ${orderDetails.address}\n` +
      `Amount: ${orderDetails.price} MAD`;

    return this.sendMessage(driverPhone, message);
  }

  // Test method to verify Twilio connection
  async testConnection() {
    try {
      const account = await this.client.api.accounts(process.env.TWILIO_ACCOUNT_SID).fetch();
      console.log('✅ Twilio connection successful');
      console.log('Account Status:', account.status);
      console.log('Account Type:', account.type);
      return true;
    } catch (error) {
      console.error('❌ Twilio connection failed:', error.message);
      return false;
    }
  }
}

module.exports = new WhatsAppService();