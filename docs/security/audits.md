# Security Audits

Manjikaze includes an automated security audit system that helps ensure your system adheres to security best practices. This document explains how the audit system works and what audits are performed.

## Automated Audit System

Security audits run automatically at startup. This ensures that security checks are performed regularly and potential issues are identified promptly.

When you start Manjikaze, the system will:

1. Check for any pending security audits that have not yet passed
2. If any pending audits are found, you'll be asked if you want to run them
3. Each audit will run and report its results
4. Audits that pass will be marked as completed and won't run again (unless you reset the state)
5. Audits that fail will remain in the pending state and will be offered to run again next time

## Security Audits Available

Manjikaze currently includes the following security audits. These can be extended in the future:

### Full Disk Encryption Audit

This audit verifies that your system is properly configured with full disk encryption using LUKS. It checks:

- That the root filesystem is mounted from an encrypted device
- That the encryption is using LUKS (Linux Unified Key Setup)
- That the encryption is properly configured and active

A system with proper disk encryption adds significant protection against unauthorized data access if your device is stolen or compromised.

### User Password Strength Audit

This audit checks if your user password meets the minimum security requirements for strength and validity. It verifies:

- Password complexity and length using the `libpwquality` scoring system
- That the password is valid for sudo authentication
- That the password meets the recommended minimum score threshold

Strong passwords are essential for protecting your system from unauthorized access, especially for administrative functions.

## Audit State Management

The audit system maintains state to avoid repeatedly running audits that have already passed. This state is stored in the Manjikaze state file and includes:

- Which audits have been run and passed
- When each audit was successfully passed

If you make significant changes to your system that might affect its security posture, you can reset the audit state to force re-running all security audits on the next startup.

## Handling Audit Failures

If an audit fails, it indicates a potential security issue with your system. You should:

1. Review the audit output to understand what failed
2. Take appropriate steps to address the issue
3. Run the audit again at the next startup to verify the issue is resolved

## Manual Audit Execution

While audits run automatically at startup, you can also manually examine the audit scripts located in the `audits/` directory of your Manjikaze installation. Each audit can be run individually for debugging or verification purposes.

---

[← Security](README.md) | [Yubikey Integration](yubikey.md)
