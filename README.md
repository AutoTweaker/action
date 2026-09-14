# AutoTweaker/action

## 概述

AutoTweaker 是一个开源的 AI Agent 框架，主仓库位于 [AutoTweaker/core](https://github.com/AutoTweaker/core)，这是 AutoTweaker 的 GitHub Actions 集成，适用于自动修改代码、修复错误、完成 issue、审查 pr 等等场景。AutoTweaker/action 本身只是将 prompt 传递给 agent，并批准 agent 的一切工具调用，不负责创建 pr，提供凭据，检出代码库等工作。agent 可以在 CI 环境中运行任意命令，读取或编辑 CI 环境工作区内的文件，如果提供了凭证，还可以访问 issue 或 pr。

action 在启动后会自动下载 AutoTweaker，安装专用适配器 [actions-adapter](https://github.com/AutoTweaker/actions-adapter)，并启动 AutoTweaker 主进程，适配器会自动完成配置、消息发送、权限审批、会话渲染，并在最终关闭 JVM。agent 的文件修改会留在工作区，agent 的其他本地操作也会在后续 step 中可见。

## 使用方式

### 示例

```yaml
name: example-workflow

on:
  workflow_dispatch:
    inputs:
      prompt:
        description: 发送给 agent 的消息，也就是任务目标
        required: true

jobs:
  autotweaker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false

      - uses: AutoTweaker/action@v1
        with:
          prompt: ${{ inputs.prompt }}
          api-key: ${{ secrets.DEEPSEEK_API_KEY }}
          provider-type: deepseek
          model-id: deepseek-flash
          reasoning: high
          base-url: https://api.deepseek.com
          workspace: ${{ github.workspace }}
          plugin-urls: |
            https://example.com/plugins/plugin-a.jar
            https://example.com/plugins/plugin-b.jar
```

请注意，actions/checkout 可能会将 GITHUB_TOKEN 带到 agent 的执行环境中，从而让 agent 获取到对于代码仓库的读写权限，在无审批的情况下这会非常危险，请务必设置 `persist-credentials: false`。如果 agent 需要访问 pr 或 issue，请自行准备只读权限的个人访问令牌。

### 参数

必填参数：

- prompt：任务目标，作为会话的第一条用户消息输入。
- api-key：用于调用 LLM 的 api 密钥。
- provider-type：支持两种内置协议类型，分别为 `deepseek` 和 `mimo`，可通过插件扩展。
- model-id：使用的模型 id。

可选参数：

- reasoning：推理等级，可选值：none、minimal、low、medium、high、xhigh，大小写不敏感。如果缺省或值非法会回退到提供商 api 默认行为。
- base-url：模型提供商的 api 端点，默认为对应 provider-type 的官方 URL。
- workspace：在 runner 上的工作目录，影响 agent 的 cwd，但不影响 agent 的访问权限，默认为 github.workspace。
- plugin-urls：要安装到 AutoTweaker 的插件直链，每行一条。安装 LlmClient 实现就可以扩展可选的 provider-type。
