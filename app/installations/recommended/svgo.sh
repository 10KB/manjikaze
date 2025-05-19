if ! command -v svgo &> /dev/null; then
    mise exec -- npm install -g svgo
fi