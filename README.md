# augustus
Small source-built container for `augustus`.

## Quick Usage

```bash
# Pull the image
docker pull docker.io/picotainers/augustus:latest

# Run the tool
docker run --rm -v "$(pwd):/data" docker.io/picotainers/augustus:latest --help
```
