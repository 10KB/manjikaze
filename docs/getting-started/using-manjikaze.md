# Using Manjikaze

After successfully installing Manjaro and the Manjikaze environment, you can begin configuring your system using the Manjikaze menu interface.

## Starting Manjikaze

Launch the Manjikaze menu by opening a terminal and typing the following command:

```bash
manjikaze
```

## Menu Navigation

The Manjikaze menu is organized into several categories:

1. **Setup** -  For installing and managing applications and development tools.
2. **Configuration** - To customize system settings, desktop environment, and developer tools preferences.
3. **Security** - Options for security hardening, Yubikey integration, and security audits.

Navigate through menus using the arrow keys and press Enter to select an option.

## Setup Menu

The Setup menu allows you to manage application installation:

1. **Install essential apps** - Installs core development tools and utilities required for most development tasks.
2. **Install recommended apps** - Installs additional useful applications that enhance the development experience.
3. **Choose optional apps** - Allows you to select and install specialized tools based on your specific needs.
4. **Update installed apps** - Updates all applications installed through Manjikaze to their latest versions.
5. **Remove preinstalled apps** - Removes unnecessary preinstalled software packages from Manjaro.

## Configuration Menu

The Configuration menu helps you customize your environment:

1. **GNOME desktop** - Configure desktop settings and appearance of the GNOME desktop environment.
2. **Nautilus file manager** - Set up preferences for the Nautilus file manager for improved file browsing and management.
3. **Monospace font** - Select and configure monospace fonts optimized for coding and terminal use.
4. **Git** - Set up your Git identity (username and email) and configure global Git settings.
5. **Network printer discovery** - Enables automatic discovery and configuration of network printers, useful for printing documents at the office.

## Security Menu

The Security menu includes options for hardening your system:

1. **Audit** - Checks and verifies system security settings to ensure they meet security requirements.
   - **Audit user password strength** - Verifies if your user password meets the minimum security requirements (length and complexity).
   - **Audit full disk encryption** - Checks if full disk encryption is properly configured and active to protect your data.
2. **Generate Yubikey secret for disk encryption** - Generates a secret key on your Yubikey that is used for disk encryption.
3. **Configure Yubikey as MFA for disk encryption** - Sets up Yubikey as a multi-factor authentication method to unlock the encrypted disk during boot.
4. **Configure Yubikey as MFA for system** - Enables Yubikey authentication as a second factor for system login, enhancing login security.
5. **Auto lock on Yubikey removal** - Automatically locks the system when the Yubikey is removed, preventing unauthorized access.
6. **Replace faulty Yubikey** - Provides a process for replacing a damaged or lost Yubikey.

## Next Steps

After initial setup, we recommend:

1. Installing essential, recommended and optional applications
2. Configure your operating system preferences
3. Setting up Yubikey security features

After installation read more detailed information about installed and configured features in the [Features documentation](../features/README.md). For more details about security features, see the [Security documentation](../security/README.md).

---

[← Installation](installation.md)
