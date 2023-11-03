# Changelog


## 2.11.0
Create ActionV2 class with non-nullable payloads in preparation for null-safety.

## 2.10.15

- Dependency upgrades

## 2.1.0
Support for react-dart 0.9.x (which moves to ReactJS 0.14)

## 2.0.0
Check out the detailed [release notes](//github.com/Workiva/w_flux/releases/tag/2.0.0).

- Store now uses a named constructor when specifying a transformer instead of an optional
constructor parameter

## 1.1.0
Check out the detailed [release notes](//github.com/Workiva/w_flux/releases/tag/1.1.0).

- Added batched redraws

## 1.0.1
Check out the detailed [release notes](//github.com/Workiva/w_flux/releases/tag/1.0.1).

- Relaxed react dependency range to include 0.8.x

## 1.0.0
Check out the detailed [release notes](//github.com/Workiva/w_flux/releases/tag/1.0.0).

There are no breaking changes in this release. The bump to 1.0.0 occurred as this project was open-sourced.

- Now using [dart_dev](//github.com/Workiva/dart_dev) for tooling
- Documentation and examples have been updated
- Reporting code coverage to Codecov.io

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
