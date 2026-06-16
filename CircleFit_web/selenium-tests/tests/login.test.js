const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const assert = require('assert');

describe('CircleFit Web Login Flow', function () {
  let driver;

  before(async function () {
    console.log("Mocha Before Hook: Starting...");
    let options = new chrome.Options();
    console.log("Mocha Before Hook: Options created");
    options.addArguments('--headless', '--no-sandbox', '--disable-dev-shm-usage');
    console.log("Mocha Before Hook: Arguments added");
    driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
    console.log("Mocha Before Hook: Driver built successfully!");

    console.log("Seeding test user via REST API...");
    try {
      const response = await fetch('http://127.0.0.1:8081/api/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: 'testuser',
          email: 'test@circlefit.com',
          password: 'test123'
        })
      });
      console.log("User seed response status:", response.status);
    } catch (err) {
      console.log("User seeding failed (likely already exists or database connecting), continuing:", err.message);
    }
  });

  after(async function () {
    if (driver) await driver.quit();
  });

  it('should validate user login and redirect to dashboard', async function () {
    console.log("Navigating directly to Login screen...");
    await driver.get('http://localhost:5173/CircleFit/#/login');
    await driver.sleep(2000);

    console.log("Locating Login page fields...");
    const emailField = await driver.wait(until.elementLocated(By.id('email')), 5000);
    const passwordField = await driver.wait(until.elementLocated(By.id('password')), 5000);
    const loginButton = await driver.wait(until.elementLocated(By.id('login-button')), 5000);
    
    assert(emailField !== null);
    assert(passwordField !== null);
    
    console.log("Typing login credentials...");
    await emailField.sendKeys('test@circlefit.com');
    await passwordField.sendKeys('test123');
    await loginButton.click();
    
    // Wait for redirect to dashboard
    await driver.wait(until.urlMatches(/CircleFit\/#\/$/), 5000);
    console.log("Login succeeded!");

    const currentUrl = await driver.getCurrentUrl();
    console.log("Target URL verified:", currentUrl);
    assert(currentUrl.includes('/CircleFit/#/'));
  });
});
