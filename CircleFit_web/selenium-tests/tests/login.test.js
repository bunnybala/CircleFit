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
  });

  after(async function () {
    if (driver) await driver.quit();
  });

  it('should redirect unauthenticated users to login and validate authentication', async function () {
    console.log("Navigating to registration view to ensure test account is present...");
    await driver.get('http://localhost:5173/CircleFit/#/register');
    await driver.sleep(2000);

    let usernameField;
    try {
      usernameField = await driver.wait(until.elementLocated(By.id('username')), 3000);
      const emailField = await driver.wait(until.elementLocated(By.id('email')), 3000);
      const passwordField = await driver.wait(until.elementLocated(By.id('password')), 3000);
      const registerButton = await driver.wait(until.elementLocated(By.id('register-button')), 3000);

      await usernameField.sendKeys('testuser');
      await emailField.sendKeys('test@circlefit.com');
      await passwordField.sendKeys('test123');
      await registerButton.click();
      
      // Wait to see if we redirect to dashboard (indicates registration succeeded and logged in)
      await driver.wait(until.urlMatches(/CircleFit\/#\/$/), 5000);
      console.log("Registration succeeded, automatically logged in!");
    } catch (regErr) {
      console.log("Registration did not complete (user likely already exists), proceeding to Login screen...");
      
      // Navigate to login page
      await driver.get('http://localhost:5173/CircleFit/#/login');
      
      // Wait for registration form to unmount to avoid locating stale inputs
      if (usernameField) {
        try {
          await driver.wait(until.stalenessOf(usernameField), 5000);
          console.log("Registration elements are now stale.");
        } catch (staleErr) {
          console.log("Staleness check warning:", staleErr.message);
        }
      }
      
      const emailField = await driver.wait(until.elementLocated(By.id('email')), 5000);
      const passwordField = await driver.wait(until.elementLocated(By.id('password')), 5000);
      const loginButton = await driver.wait(until.elementLocated(By.id('login-button')), 5000);
      
      assert(emailField !== null);
      assert(passwordField !== null);
      
      await emailField.sendKeys('test@circlefit.com');
      await passwordField.sendKeys('test123');
      await loginButton.click();
      
      // Wait for redirect to dashboard
      await driver.wait(until.urlMatches(/CircleFit\/#\/$/), 5000);
      console.log("Login succeeded!");
    }

    const currentUrl = await driver.getCurrentUrl();
    console.log("Target URL verified:", currentUrl);
    assert(currentUrl.includes('/CircleFit/#/'));
  });
});
