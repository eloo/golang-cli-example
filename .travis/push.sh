#!/bin/sh
# Credit: https://gist.github.com/willprice/e07efd73fb7f13f917ea

setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

push() {
  # Remove existing "origin"
  git remote rm origin
  # Add new "origin" with access token in the git URL for authentication
  git remote add origin https://eloo:${GITHUB_RELEASE_TOKEN}@github.com/eloo/golang-cli-example.git # > /dev/null 2>&1
  git push origin master # --quiet
}

setup_git

push