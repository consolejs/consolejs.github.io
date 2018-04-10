#!/bin/bash

echo '生成静态资源中……'

hexo generate

echo '发布中……'

hexo  deploy

echo "------------"
echo "---> succeed."
echo "------------"