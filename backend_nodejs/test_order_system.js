const { generateDailyUserPrefix, generateNextOrderNumber } = require('./controllers/ordersController.js');

// Test the daily prefix generation
console.log('Testing Daily Prefix Generation:');
console.log('User 1, Day 1:', generateDailyUserPrefix(1, 1));
console.log('User 1, Day 2:', generateDailyUserPrefix(1, 2));
console.log('User 2, Day 1:', generateDailyUserPrefix(2, 1));
console.log('User 2, Day 2:', generateDailyUserPrefix(2, 2));

// Test current day
const currentDay = Math.floor((Date.now() - new Date(new Date().getFullYear(), 0, 0)) / (1000 * 60 * 60 * 24));
console.log('\nCurrent day of year:', currentDay);
console.log('User 1 today:', generateDailyUserPrefix(1, currentDay));
console.log('User 2 today:', generateDailyUserPrefix(2, currentDay));
console.log('User 3 today:', generateDailyUserPrefix(3, currentDay));

console.log('\nTesting Order Number Generation:');
console.log('Order 1:', generateNextOrderNumber(1));
console.log('Order 25:', generateNextOrderNumber(25));
console.log('Order 999999:', generateNextOrderNumber(999999));
