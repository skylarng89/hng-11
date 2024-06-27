const appVersion = '1.0.0';

console.log(`App Version: ${appVersion}`);

// Obfuscate email address
const user = 'onaziken';
const domain = 'gmail.com';
const email = `${user}@${domain}`;

document.getElementById('email').innerHTML = `${email}`;
