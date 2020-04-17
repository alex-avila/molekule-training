#!/bin/bash
set -eo pipefail

# Compress static files with gzip and brotli
# https://blog.e-kursy.it/aws-lambda-edge-brotli/
# https://medium.com/@felice.geracitano/brotli-compression-delivered-from-aws-7be5b467c2e1
cd ./.nuxt/dist/
find -L ./client -name '*.js' -o -name '*.json' -o -name '*.svg' -o -name '*.woff' -o -name '*.woff2' \
 | xargs -n 1 -I {} sh -c 'mkdir -p ./gz/`dirname $1` && cp {} ./gz/{} && gzip --best ./gz/{} && mv ./gz/{}.gz ./gz/{}' sh {}
find -L ./client -name '*.js' -o -name '*.json' -o -name '*.svg' -o -name '*.woff' -o -name '*.woff2' \
 | xargs -n 1 -I {} sh -c 'mkdir -p ./br/`dirname $1` && cp {} ./br/{} && brotli --best ./br/{} && mv ./br/{}.br ./br/{}' sh {}
cd ../..

aws s3 cp --recursive --cache-control 'public, max-age=31536000' ./.nuxt/dist/client s3://elasticbeanstalk-us-east-1-411004368230/${CIRCLE_BRANCH}/_nuxt/
aws s3 cp --recursive --cache-control 'public, max-age=31536000' --content-encoding gzip ./.nuxt/dist/gz/client s3://elasticbeanstalk-us-east-1-411004368230/${CIRCLE_BRANCH}/gzip/_nuxt/
aws s3 cp --recursive --cache-control 'public, max-age=31536000' --content-encoding br ./.nuxt/dist/br/client s3://elasticbeanstalk-us-east-1-411004368230/${CIRCLE_BRANCH}/br/_nuxt/

rm -rf node_modules
yarn --prod

eb deploy MolekuleTraining-$CIRCLE_BRANCH-env
