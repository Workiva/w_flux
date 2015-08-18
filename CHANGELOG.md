# Changelog

## 0.3.0
Check out the detailed [release notes](//github.com/Workiva/w_flux/releases/tag/0.3.0).

- Actions are now awaitable
- FluxComponent provides a default implementation of getStoreHandlers
- FluxComponent adds redrawOn
- triggerOnAction with async onAction functions now works properly
- **BREAKING CHANGE** &nbsp; Store no longer extends Stream
- **BREAKING CHANGE** &nbsp; FluxComponent's `stores` getter is now `store`

## 0.2.0
- Shorter action dispatch
- Add triggerOnAction to store 
- Support throttling of store triggers
- Allow react-dart 0.7.x releases

## 0.1.0
- Initial version of w_flux
