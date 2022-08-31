---
title: Lerna 多包管理工具的探索
date: 2019-08-14 14:12:21
categories: 前端
tags: 
- 开发环境
- 前端
---

<style type="text/css">
    .br10{border-radius: 6px;}
</style>

<img class="br10 k-lazy" src="/2019/08/14/lerna/lerna.jpg">

<!-- more -->

基于[create-react-app](https://github.com/facebook/create-react-app) 其源码中有个 `lerna.json` 文件，经了解使用 [Lerna](https://github.com/lerna/lerna) 可以用来管理项目中多个 packages，这正是值得学习和探究的。本文主要对 Lerna 的使用做个简单介绍。

<img class="br10 k-lazy" src="/2019/08/14/lerna/p0.jpg">


<br />



## Lerna 是什么 🤔 

> Lerna is a tool that optimizes the workflow around managing multi-package repositories with git and npm.

**Lerna** 是一个基于 git 和 npm 管理多个 packages 来简化工作流程的工具。

<!-- more -->

## 安装 Lerna

```bash
# npm
npm install --global lerna || npm install -g lerna

# yarn
yarn global add lerna
```

如果不想安装，也可以使用 [npx](https://www.npmjs.com/package/npx)。

## 初始化项目

创建项目
```bash
git init lerna-repo && cd lerna-repo
```
使用 Lerna 初始化项目

```bash
lerna init
```

此时项目结构如下：
```
.
├── lerna.json
├── package.json
└── packages
```

## 创建 packages

>为了方便理解，这里假设有三个 packages：banana、apple、grocery。其中 grocery 依赖于 banana、apple 两个 package。

在 `packages/` 目录下创建 **banana**、**apple**、**grocery** 三个目录：

```bash
mkdir banana apple grocery
```

然后分别在 **banana**、**apple**、**grocery** 目录下执行如下命令初始化 package：

```bash
npm init -y
```

并分别创建一个`index.js`文件，增加如下代码：
```js
// apple index.js
module.exports = 'apple package';
```
```js
// banana index.js
module.exports = 'banana package';
```
```js
// grocery index.js
const apple = require('apple');
const banana = require('banana');

console.log('all the dependencies of the grocery package:');
console.log(apple);
console.log(banana);
```

此时目录结构如下：
```
.
├── lerna.json
├── package.json
└── packages
    ├── apple
    │   ├── index.js
    │   └── package.json
    ├── banana
    │   ├── index.js
    │   └── package.json
    └── grocery
        ├── index.js
        └── package.json
```


### 创建 packages 依赖关系

上一步骤已创建了 **banana**、**apple**、**grocery** 三个 packages，其中 **grocery** 依赖于 **banana**、**apple**。要建立此依赖只需执行如下命令：

```js
// add apple to grocery as a dependency
lerna add apple packages/grocery
// add banana to grocery as a dependency
lerna add banana packages/grocery
```

`lerna add` 类似于 `npm install`。

此时目录结构如下：

```
.
├── lerna.json
├── package.json
└── packages
    ├── apple
    │   ├── index.js
    │   └── package.json
    ├── banana
    │   ├── index.js
    │   └── package.json
    └── grocery
        ├── index.js
        ├── node_modules
        │   ├── apple -> ../../apple
        │   └── banana -> ../../banana
        └── package.json
```
在 **grocery** 的 `node_modules` 下，Lerna 会分别为 **banana**、**apple** 创建一个链接到对应 package 的 symlink（符号链接或软连接，相当于 Windows 中快捷方式)。这样对 **banana**、**apple** 任何修改都能立刻生效。
```
    ├── node_modules
    │   ├── apple -> ../../apple
    │   └── banana -> ../../banana
```

## 运行
为了方便运行代码，对根目录下 `package.json` 文件增加如下代码：
```js
  "scripts": {
    "start": "node packages/grocery/index.js"
  }
```
执行如下命令，运行代码

```js
npm start
```
输出
```js
> root@ start /Users/v6let/github/lerna-repo
> node packages/grocery/index.js

all the dependencies of the grocery package:
apple package
banana package
```

## 添加第三方依赖

为所有的 packages 添加 eslint.

```js
lerna add eslint --dev
```
这里只有三个 packages，如果存在很多 packages，每个 package 都单独安装 eslint 包，这会造成资源的浪费。Lerna 也考虑到这个问题，提供了如下命令来解决：
```js
lerna bootstrap --hoist
```
`lerna bootstrap` 会根据每个 package 的 `package.json` 为其安装依赖。如果加上 `--hoist` 参数，Lerna 会把所有 packages 中共有的依赖包安装到根目录中，然后分别在各自的 `node_modules/.bin` 中创建软链接指向对应依赖包的实际路径。

```
├── apple
│   ├── index.js
│   ├── node_modules
│   │   └── .bin
│   │       └── eslint -> ../../../../node_modules/eslint/bin/eslint.js
│   ├── package-lock.json
│   └── package.json
├── banana
│   ├── index.js
│   ├── node_modules
│   │   └── .bin
│   │       └── eslint -> ../../../../node_modules/eslint/bin/eslint.js
│   ├── package-lock.json
│   └── package.json
└── grocery
    ├── index.js
    ├── node_modules
    │   └── .bin
    │       └── eslint -> ../../../../node_modules/eslint/bin/eslint.js
    ├── package-lock.json
    └── package.json
```

当然如果只是安装开发依赖包，可以直接安装在根目录下即可。

```js
// npm
npm install -D eslint

// yarn
yarn add -D eslint
```
因为 node 在查找模块时，会从当前目录向上逐级查找。

当然，也许只想对特定 package 安装依赖包，可以通过如下方式：

```js
 lerna add lodash --scope=grocery
```
使用 `--scope` 参数来指定安装位置。

## 版本管理

Lerna 提供了两种版本管理模式：
- Fixed/Locked mode (default)

  任何 package 更新发布，都统一由根目录下 `lerna.json` 中的 `version` 字段来记录跟踪。即这种模式会将所有 packages 版本号关联起来。但这样会存在一个问题：
  任何 package 版本号变化，都会导致其他所有 package 拥有一个新的版本号。
  
  开启方法：默认模式。

- Independent mode (--independent)

  packages 发布新版时，会逐个询问每个 package 需要升级的版本号。即每个 package 都独立维护自己的 version。这样就可以有效地避免默认模式下版本号语义化的问题。
  
  开启方法：
    - `lerna init --independent`
    - 将 `lerna.json` 中的 `version` 字段设置为 `'independent'`

## 发布
要发布新版时，只需执行如下命令即可。

```bash
lerna publish
```
另外，Lerna 还为 `lerna publish` 提供了一些选项：[@lerna/publish](https://github.com/lerna/lerna/tree/master/commands/publish#readme)。

在执行该命令时，需要注意，至少要有个 **commit**，否则会得到如下提示：
> Working tree has uncommitted changes, please commit or remove changes before continuing.

或

> Current HEAD is already released, skipping change detection.

因为在发布之前，Lerna 会检查 packages 是否有更新。如果有更新才会以 **一问一答** 的方式获取发布相关信息：

>假设已登录 NPM。[如何注册及登录](https://docs.npmjs.com/creating-a-new-npm-user-account)

```
info cli using local version of lerna
lerna notice cli v3.13.1
lerna info current version 0.0.5
lerna info Looking for changed packages since v6let-apple@0.0.5
? Select a new version (currently 0.0.5) Patch (0.0.6)

Changes:
 - v6let-apple: 0.0.5 => 0.0.6
 - v6let-banana: 0.0.4 => 0.0.6
 - v6let-grocery: 0.0.4 => 0.0.6

? Are you sure you want to publish these packages? Yes
lerna info execute Skipping GitHub releases
lerna info git Pushing tags...
lerna info publish Publishing packages to npm...
....
```
>为了能成功将 apple、banana、grocery 发布到 NPM，在包命名时都为每个 package 加了 `v6let-` 前缀。

上述是默认模式下的输出信息。虽然只对 **v6let-apple** 做了修改，然而在版本号更新时，会更新所有 packages 的版本号。而且如果执行发布，会把所有的 packages 都发布到 NPM。那如果换成`Independent`模式，会是怎样呢？

```
info cli using local version of lerna
lerna notice cli v3.13.1
lerna info versioning independent
lerna info Looking for changed packages since v0.0.7
? Select a new version for v6let-apple (currently 0.0.7) Patch (0.0.8)

Changes:
 - v6let-apple: 0.0.7 => 0.0.8

? Are you sure you want to publish these packages? Yes
lerna info execute Skipping GitHub releases
lerna info git Pushing tags...
lerna info publish Publishing packages to npm...
```
在 **Independent** 模式下，只会更新已更新 **v6let-apple** 的版本号，并只将其发布到 NPM。


## 其他常用命令

- `lerna create <name> [loc]`：在 `loc` 目录下创建一个 package。默认位置 `packages/`。
- `lerna version`：更新 package 的版本号。提供 Patch、Minor、Major、Prepatch、Preminor、Premajor、Custom Prerelease、Custom Version 选项。
- `lerna clean`：删除所有 packages 的 node_modules 目录。PS：不会删除根目录的 node_modules。
- `lerna list` | `lerna ls` | `lerna ll` | `lerna la`：列举 packages 目录下的所有本地 packages。
  ```js
  // 执行 lerna list 的输出：
  info cli using local version of lerna
  lerna notice cli v3.13.1
  apple
  banana
  grocery
  lerna success found 3 packages
  ```
- `lerna changed` | `lerna updated`：查看本地 packages 是否发生变化。
- `lerna link`：根据依赖关系为本地所有 packages 创建软链接。
- `lerna run <script>`：运行每个 package 中包含 `npm run <script>` 的脚本。