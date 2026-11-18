# Browser Policies

Manjikaze sets machine policies for Google Chrome, Chromium, Brave and Firefox. A machine policy applies to every profile on the computer, and you can't change it in the browser's settings.

## What Is Set

| Policy | Browsers | Effect |
|--------|----------|--------|
| `MetricsReportingEnabled: false` | Chrome, Chromium, Brave | No usage statistics or crash reports are sent to Google |
| `UrlKeyedAnonymizedDataCollectionEnabled: false` | Chrome, Chromium, Brave | The addresses of pages you visit aren't sent to Google to improve searches and browsing |
| `PromotionsEnabled: false` | Chrome, Chromium, Brave | No promotional pages and product tips |
| `ExtensionInstallForcelist` (Chromium-based), `ExtensionSettings` (Firefox) | Chrome, Chromium, Brave, Firefox | The Bitwarden extension is installed in every profile and can't be removed or disabled |
| `BraveP3AEnabled: false`, `BraveStatsPingEnabled: false`, `BraveWebDiscoveryEnabled: false` | Brave | No product analytics, usage ping or Web Discovery data is sent to Brave |
| `DisableTelemetry`, `DisableFirefoxStudies` | Firefox | No telemetry is sent to Mozilla and no studies run |
| `FirefoxHome`, `FirefoxSuggest`, `UserMessaging` | Firefox | No sponsored shortcuts, stories or suggestions, and no recommendations. These are defaults: you can turn them back on in the settings |

The extension still needs you to sign in to your Bitwarden account once per profile.

## Where the Policies Live

| Browser | File |
|---------|------|
| Google Chrome | `/etc/opt/chrome/policies/managed/manjikaze.json` |
| Chromium | `/etc/chromium/policies/managed/manjikaze.json` |
| Brave | `/etc/brave/policies/managed/manjikaze.json` and `manjikaze-brave.json` |
| Firefox | `/etc/firefox/policies/policies.json` |

Manjikaze creates these directories even when a browser isn't installed, so a browser you install later starts with the policies. The policy files come from `configs/browser-policies/` in Manjikaze.

## Applying the Policies

A new installation gets the policies with the essential apps, under the name `browser-policies`. An existing installation gets them through a migration when you start Manjikaze. To apply them again, for example after a policy file was changed or removed, run `manjikaze` and choose **Security → Apply browser policies**. Restart open browsers afterwards.

To see which policies are active, open `chrome://policy` in Chrome and Chromium, `brave://policy` in Brave or `about:policies` in Firefox.

## Adding Your Own Policies

Chromium-based browsers read every JSON file in their managed directory. Add a file of your own next to `manjikaze.json`, for example `/etc/opt/chrome/policies/managed/company.json`. Manjikaze only replaces its own files.

When a policy appears in more than one file, the browser takes its whole value from the last file in alphabetical order, so don't repeat a policy that `manjikaze.json` sets. To install or block other extensions, use `ExtensionSettings`: Manjikaze installs Bitwarden through `ExtensionInstallForcelist`, and the browser applies both.

Firefox reads a single `policies.json`. Manjikaze merges its policies into that file, so policies you add yourself stay. For a policy that both set, Manjikaze's value wins the next time the policies are applied.

The [Chrome Enterprise policy list](https://chromeenterprise.google/policies/), [Brave's group policies](https://support.brave.app/hc/en-us/articles/360039248271) and [Mozilla's policy templates](https://mozilla.github.io/policy-templates/) describe all available policies.

## Removing the Policies

Run `manjikaze`, choose **Setup → Uninstall apps** and select `browser-policies`. That deletes Manjikaze's files from the Chromium-based browsers and removes its policies from Firefox's `policies.json`; policies that someone else added stay, and the file goes when nothing is left. Restart open browsers afterwards. Choosing **Apply browser policies** adds the policies again.
