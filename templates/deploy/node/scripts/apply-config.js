#!/usr/bin/env node

/**
 * Configuration Management Script
 * 
 * This script reads from .env.config and applies values to various 
 * configuration files throughout the project.
 */

const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');
const { exec } = require('child_process');

// Configuration
const ENV_CONFIG_PATH = '.env.config';
const FILES_TO_UPDATE = [
  { 
    path: 'Dockerfile',
    template: 'Dockerfile.template'
  },
  { 
    path: 'docker-compose.yml',
    template: 'docker-compose.template.yml'
  },
  {
    path: '.github/workflows/deploy.yml',
    template: '.github/workflows/deploy.template.yml'
  }
];

// Ensure required directories exist
const ensureDirectoryExists = (filePath) => {
  const dirname = path.dirname(filePath);
  if (fs.existsSync(dirname)) return;
  
  fs.mkdirSync(dirname, { recursive: true });
  console.log(`Created directory: ${dirname}`);
};

// Parse .env.config file
const parseEnvConfig = () => {
  try {
    if (!fs.existsSync(ENV_CONFIG_PATH)) {
      console.error(`Error: ${ENV_CONFIG_PATH} not found.`);
      process.exit(1);
    }
    
    const envConfig = dotenv.parse(fs.readFileSync(ENV_CONFIG_PATH));
    
    // Process any variables that reference other variables
    let configChanged = true;
    const processedConfig = { ...envConfig };
    
    // Resolve variable references (e.g., ${VAR_NAME}) up to 5 iterations
    // to handle nested references
    for (let i = 0; i < 5 && configChanged; i++) {
      configChanged = false;
      
      for (const [key, value] of Object.entries(processedConfig)) {
        const newValue = value.replace(/\${([A-Za-z0-9_]+)}/g, (match, varName) => {
          if (processedConfig[varName]) {
            configChanged = true;
            return processedConfig[varName];
          }
          return match; // Keep original if not found
        });
        
        if (newValue !== value) {
          processedConfig[key] = newValue;
        }
      }
    }
    
    return processedConfig;
  } catch (error) {
    console.error(`Error parsing ${ENV_CONFIG_PATH}:`, error);
    process.exit(1);
  }
};

// Replace placeholders in a string with values from config
const replacePlaceholders = (content, config) => {
  return content.replace(/\${([A-Za-z0-9_]+):-([^}]*)}/g, (match, varName, defaultValue) => {
    return config[varName] || defaultValue;
  });
};

// Create template files if they don't exist
const createTemplateIfNeeded = (filePath, templatePath) => {
  if (fs.existsSync(templatePath)) {
    return;
  }
  
  if (!fs.existsSync(filePath)) {
    console.error(`Error: Neither ${filePath} nor ${templatePath} exist.`);
    return;
  }
  
  // Create template from original file
  const content = fs.readFileSync(filePath, 'utf8');
  ensureDirectoryExists(templatePath);
  fs.writeFileSync(templatePath, content);
  console.log(`Created template: ${templatePath}`);
};

// Apply configuration to files
const applyConfig = (config) => {
  for (const file of FILES_TO_UPDATE) {
    try {
      createTemplateIfNeeded(file.path, file.template);
      
      if (!fs.existsSync(file.template)) {
        console.warn(`Warning: Template ${file.template} not found, skipping.`);
        continue;
      }
      
      const templateContent = fs.readFileSync(file.template, 'utf8');
      const newContent = replacePlaceholders(templateContent, config);
      
      ensureDirectoryExists(file.path);
      fs.writeFileSync(file.path, newContent);
      console.log(`Updated: ${file.path}`);
    } catch (error) {
      console.error(`Error updating ${file.path}:`, error);
    }
  }
};

// Update package.json with config values
const updatePackageJson = (config) => {
  try {
    const packageJsonPath = 'package.json';
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
    
    // Update fields
    packageJson.name = config.APP_NAME || packageJson.name;
    packageJson.description = config.APP_DESCRIPTION || packageJson.description;
    packageJson.license = config.APP_LICENSE || packageJson.license;
    
    if (packageJson.engines && config.NODE_MIN_VERSION) {
      packageJson.engines.node = `>=${config.NODE_MIN_VERSION}`;
    }
    
    fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));
    console.log('Updated: package.json');
  } catch (error) {
    console.error('Error updating package.json:', error);
  }
};

// Create backup of a file
const backupFile = (filePath) => {
  if (!fs.existsSync(filePath)) return;
  
  const backupPath = `${filePath}.bak`;
  fs.copyFileSync(filePath, backupPath);
  console.log(`Created backup: ${backupPath}`);
};

// Main function
const main = () => {
  console.log('🔧 Applying configuration from .env.config...');
  
  // Parse config
  const config = parseEnvConfig();
  console.log('Loaded configuration values:', config);
  
  // Create backups
  FILES_TO_UPDATE.forEach(file => backupFile(file.path));
  backupFile('package.json');
  
  // Apply configuration
  applyConfig(config);
  updatePackageJson(config);
  
  console.log('✅ Configuration applied successfully!');
};

// Run the script
main();
