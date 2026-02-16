import { defineConfig } from 'vitepress';

// Shared sidebar configuration for all documentation pages
const docsSidebar = [
    {
        text: 'Getting Started',
        collapsed: false,
        items: [
            { text: 'Overview', link: '/getting-started/overview' },
            { text: 'Preparations', link: '/getting-started/preparations' },
            { text: 'Installation', link: '/getting-started/installation' },
            { text: 'Using Manjikaze', link: '/getting-started/using-manjikaze' },
        ],
    },
    {
        text: 'Features',
        collapsed: true,
        items: [
            { text: 'Overview', link: '/features/overview' },
            { text: 'Navigation & Hotkeys', link: '/features/navigation' },
            { text: 'Tiling', link: '/features/tiling' },
            { text: 'Terminal', link: '/features/terminal' },
            { text: 'Shell Tools', link: '/features/shell-tools' },
            { text: 'GUI Applications', link: '/features/gui' },
            { text: 'Runtime Manager', link: '/features/mise-runtime-manager' },
            { text: 'AWS Tools', link: '/features/aws-tools' },
            { text: 'Cursor Installation', link: '/features/cursor-installation' },
        ],
    },
    {
        text: 'Security',
        collapsed: true,
        items: [
            { text: 'Overview', link: '/security/overview' },
            { text: 'Security Audits', link: '/security/audits' },
            { text: 'Yubikey Integration', link: '/security/yubikey' },
            { text: 'YubiKey GPG & SSH', link: '/security/yubikey-gpg-ssh' },
            { text: 'Disk Encryption', link: '/security/disk-encryption' },
        ],
    },
    {
        text: 'Maintenance',
        collapsed: true,
        items: [
            { text: 'Overview', link: '/maintenance/overview' },
            { text: 'Updates', link: '/maintenance/updates' },
            { text: 'Migrations', link: '/maintenance/migrations' },
            { text: 'Troubleshooting', link: '/maintenance/troubleshooting' },
        ],
    },
];

export default defineConfig({
    title: 'Manjikaze',
    description: 'Linux workstation provisioning for 10KB developers',

    base: '/',

    lastUpdated: true,

    themeConfig: {
        nav: [
            { text: 'Getting Started', link: '/getting-started/overview' },
            { text: 'Features', link: '/features/overview' },
            { text: 'Security', link: '/security/overview' },
            { text: 'Maintenance', link: '/maintenance/overview' },
        ],

        sidebar: {
            '/getting-started/': docsSidebar,
            '/features/': docsSidebar,
            '/security/': docsSidebar,
            '/maintenance/': docsSidebar,
        },

        socialLinks: [{ icon: 'github', link: 'https://github.com/10kb/manjikaze' }],

        footer: {
            copyright: 'Copyright © 2025 10KB',
        },

        search: {
            provider: 'local',
        },

        outline: {
            level: [2, 3],
        },

        editLink: {
            pattern: 'https://github.com/10kb/manjikaze/edit/main/docs/:path',
            text: 'Edit this page on GitHub',
        },
    },

    head: [
        ['meta', { name: 'theme-color', content: '#646cff' }],
        ['meta', { property: 'og:type', content: 'website' }],
        ['meta', { property: 'og:title', content: 'Manjikaze' }],
        [
            'meta',
            {
                property: 'og:description',
                content: 'Linux workstation provisioning for 10KB developers',
            },
        ],
    ],
});
