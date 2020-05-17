module.exports = {
  root: true,
  extends: ["@react-native-community", "./node_modules/gts"],
  parser: ['@typescript-eslint/parser', "simple-import-sort"],
  plugins: ['@typescript-eslint'],
  rules: {
    noUseBeforeDeclare: false,
    "@typescript-eslint/member-delimiter-style": [
      "error",
      {
        "multiline": {
          "delimiter": "none",
          "requireLast": false
        },
        "singleline": {
          "delimiter": "semi"
        }
      }
    ],
    "simple-import-sort/sort": [
      "error",
      {
        "groups": [["^\\u0000", "^@?\\w", "^[^.]", "^\\."]]
      }
    ]
  }
};
