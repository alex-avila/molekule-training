#!/bin/bash
set -eo pipefail

echo "Start deploy"

# Compress static files with gzip and brotli
# https://blog.e-kursy.it/aws-lambda-edge-brotli/
# https://medium.com/@felice.geracitano/brotli-compression-delivered-from-aws-7be5b467c2e1
cd ./.nuxt/dist/
echo $PWD
find -L ./client -name '*.js' -o -name '*.json' -o -name '*.svg' -o -name '*.woff' -o -name '*.woff2' \
 | xargs -n 1 -I {} sh -c 'mkdir -p ./gz/`dirname $1` && cp {} ./gz/{} && gzip --best ./gz/{} && mv ./gz/{}.gz ./gz/{}' sh {}
find -L ./client \( -name '*.js' -o -name '*.json' -o -name '*.svg' -o -name '*.woff' -o -name '*.woff2' \) \
 -exec mkdir -p ./br/client \; -exec cp {} ./br/{} \; -exec brotli -f --best ./br/{} \; -exec mv ./br/{}.br ./br/{} \;
cd ../..

aws s3 cp --recursive --cache-control 'public, max-age=31536000' ./.nuxt/dist/client s3://elasticbeanstalk-us-east-2-110898720018/${CIRCLE_TAG}/_nuxt/
aws s3 cp --recursive --cache-control 'public, max-age=31536000' --content-encoding gzip ./.nuxt/dist/gz/client s3://elasticbeanstalk-us-east-2-110898720018/${CIRCLE_TAG}/gz/_nuxt/
aws s3 cp --recursive --cache-control 'public, max-age=31536000' --content-encoding br ./.nuxt/dist/br/client s3://elasticbeanstalk-us-east-2-110898720018/${CIRCLE_TAG}/br/_nuxt/

eb deploy $CIRCLE_BRANCH-env
