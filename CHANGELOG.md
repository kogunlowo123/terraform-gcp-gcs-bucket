# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-15

### Added

- Initial release of the GCS Bucket Terraform module.
- Bucket creation with configurable location, storage class, and access controls.
- Object versioning support.
- Comprehensive lifecycle rules with all condition types.
- CORS configuration for cross-origin requests.
- Retention policies with optional locking.
- Uniform bucket-level access with public access prevention.
- CMEK encryption via Cloud KMS.
- Autoclass for automatic storage class transitions.
- Soft delete policy configuration.
- Access logging to a target bucket.
- Static website hosting configuration.
- Custom dual-region placement.
- IAM bindings at the bucket level.
- Pub/Sub notifications for object events.
- Comprehensive examples: basic, advanced, and complete.

## [0.1.0] - 2024-01-01

### Added

- Initial development version with core bucket functionality.
