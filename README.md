# samjs-install

A dynamic install server for [samjs](https://github.com/SAMjs/samjs).

## Getting Started
```sh
npm install --save samjs-install
npm install --save-dev samjs-install-deps
```

## Usage

```js
// server-side
samjs
  .plugins(require("samjs-install")(options))
  .options()
  .configs()
  .models()
  .startup()
```
