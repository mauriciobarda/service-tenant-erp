import js from '@eslint/js'
import { defineConfig } from 'eslint/config'
import eslintConfigPrettier from 'eslint-config-prettier'
import globals from 'globals'
import tseslint from 'typescript-eslint'
import security from 'eslint-plugin-security'
import pluginN from 'eslint-plugin-n'

export default defineConfig([
  // Global ignores
  {
    ignores: [
      '**/dist/**',
      '**/build/**',
      '**/coverage/**',
      '**/node_modules/**'
    ]
  },

  // Base configurations
  js.configs.recommended,
  ...tseslint.configs.recommended,

  // API App context (Node.js backend)
  {
    files: ['apps/api/**/*.{js,mjs,cjs,ts,mts,cts}'],
    plugins: {
      n: pluginN,
      security: security
    },
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.node
    },
    rules: {
      ...security.configs.recommended.rules,
      ...pluginN.configs['recommended-module'].rules,

      'no-console': ['error', { allow: ['info', 'warn', 'error'] }]
    }
  },

  // Prettier formatting
  eslintConfigPrettier
])
