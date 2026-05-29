# Code Quality Gate 调研报告

**日期**：2026-05-23
**作者**：codex (GPT-5.5) via `codex exec`，由 kiro-workflow task 主 agent 编排
**目的**：为 `kiro-workspace` 设计 **A+B+C 三层 defense-in-depth** 代码品质 gate

---

## 调研方法

通过 `codex exec`（OpenAI Codex CLI 0.133.0，GPT-5.5 模型）做了 3 次独立调研，按三层组织：

| 层 | 抓什么 | 输出 |
|---|---|---|
| **A** | prompt-level 约束（让 LLM 不去写差代码） | 反模式清单 + steering rules |
| **B** | 工具硬 gate（CI 失败阻止 merge） | 多语言工具矩阵 + 阈值 |
| **C** | LLM-as-judge review agent（语义级兜底） | reviewer prompt + output 格式 |

每层一份独立 codex query，避免上下文污染。下面是 codex 的原始产出，未编辑——保留独立第二意见的本貌。

---

# A 层：Prompt 约束 + LLM Codegen 反模式

Reading additional input from stdin...
OpenAI Codex v0.133.0
--------
workdir: /home/sharp/projects/kiro-workspace
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: none
reasoning summaries: none
session id: 019e5249-8ddf-7540-a8b4-4aec58f9ac8b
--------
user
我在为 AI codegen 工具设计 prompt-level 代码质量约束。请综合论文/工程实践，回答：1. LLM 生成代码的典型反模式有哪些（特别是 defensive over-coding、hallucinated abstractions、重复 validation 跨文件）？ 2. 哪些 prompt engineering 技巧能让 LLM 避免这些反模式？引用具体研究（arxiv / ICSE / FSE / NeurIPS 2023-2026 优先）。 3. 推荐 5-10 条可写进 system prompt / steering rules 的具体规则，每条说明覆盖哪种反模式。 4. 已知工业实践（Aider / Cursor / Sweep / Continue.dev）的 prompt 约束做法。请用中文回答，markdown 格式，给出 paper title + URL（如有）。
codex
我会先核对近几年论文和工具公开提示词/文档，重点找可落到 steering rules 的证据，而不是只给泛泛建议。
web search: 
web search: LLM generated code anti patterns over engineering defensive programming hallucinated abstractions validation duplication paper 2023 2024 arxiv ...
web search: 
web search: Aider system prompt code editing instructions repository conventions don't over engineer ...
web search: 
web search: github sweepai sweep system prompt "No overengineering" ...
web search: 
web search: github.com Aider-AI aider prompts system prompt edit block "Do not skip" ...
web search: 
web search: Prompt Engineering for Code Generation A systematic literature review 2024 arxiv ...
web search: 
web search: https://arxiv.org/abs/2604.06373
web search: 
web search: https://docs.cursor.com/context/rules
web search: 
web search: Sweep AI GitHub prompt "Modify" "codebase" "system" "repo" ...
web search: 
web search: package hallucination LLM code generation 19.7% packages hallucinated arxiv 2024 ...
codex
## 结论先行

LLM codegen 的主要质量风险不是“写不出代码”，而是**在局部可运行的前提下制造长期维护债**：重复实现、重复 validation、过度 error handling、凭空 API/包/抽象、绕开既有架构。近两年论文也从 HumanEval 式函数正确性，转向 repo-level consistency、hallucination、design smells 和 prompt/flow engineering。

## 1. 典型反模式

| 反模式 | 表现 | 研究/实践对应 |
|---|---|---|
| Defensive over-coding | 每层都 `try/catch`、null check、schema validation；把不可能状态也写成分支；吞错或包装错误导致真实 bug 被隐藏 | AI IDE 大型项目研究发现 Exception-Handling Issues、High Complexity、Large Methods 常见；这些不是功能错误，但损害可维护性。见 *Beyond Functional Correctness*：https://arxiv.org/abs/2604.06373 |
| Hallucinated abstractions | 新建 `Manager/Service/Factory/Adapter`，但项目没有对应层次；为一次性需求抽象接口、策略、插件系统 | 同上论文报告 Code Duplication、Framework Best-Practice Violations、SRP/SoC/DRY 违背。 |
| Hallucinated APIs / objects / attributes | 调用不存在的方法、字段、类、配置项；把相似库 API 混用 | *Bugs in Large Language Models Generated Code* 归纳了 Hallucinated Object、Wrong Attribute、Wrong Input Type 等 10 类 bug：https://arxiv.org/abs/2403.08937 |
| Hallucinated dependencies | 引入不存在的 npm/PyPI 包，或使用名字相近但错误的包 | *We Have a Package for You!* 在 576,000 个样本中发现商业模型和开源模型均存在包幻觉，开源模型更严重：https://arxiv.org/abs/2406.10279 |
| 重复 validation 跨文件 | controller、service、repository、client SDK、UI form 都重复校验同一字段；规则漂移后产生不一致 | 属于 Code Duplication + Inconsistent repository-level behavior。De-Hallucinator 指出模型常不能正确复用项目已有 API，容易“变体式重复实现”：https://arxiv.org/abs/2401.01701 |
| Non-prompted consideration | 用户没要求的缓存、权限系统、多租户、重试、队列、国际化、抽象层 | *Bugs in LLM Generated Code* 明确列出 Non-Prompted Consideration 和 Prompt-biased code。 |
| Context-blind implementation | 不读现有调用点、类型、约定，直接生成孤立代码 | 2026 survey 指出 repo-level context、一致性、可靠性保证仍是关键缺口：https://link.springer.com/article/10.1007/s10489-026-07230-0 |
| Lazy coding / incomplete edit | `// existing code here`、伪代码、漏改调用点、只改 happy path | Aider 文档提到某些 edit format 会诱发模型省略大段代码，用占位注释代替真实编辑：https://aider.chat/docs/more/edit-formats.html |
| Validation bypass by tests | 写测试只覆盖自己生成的行为，避开真实 edge cases；或修改测试适配错误实现 | AlphaCodium 的结果说明单次 prompt 不足，测试驱动、多阶段 flow 显著优于单 prompt：https://arxiv.org/abs/2401.08500 |

## 2. 有效的 Prompt Engineering 技巧

### Grounding：先锚定真实代码，再生成

De-Hallucinator 的核心发现是：LLM 常生成“看起来接近”的代码，但不会正确引用项目已有 API；通过检索相关 API 参考并迭代注入 prompt，可显著减少 hallucinated API 和重复实现。  
适合写进 prompt：

> 在新增函数/类/validation 之前，必须先搜索同名、相似职责、相同 schema、相同错误处理模式；优先复用或扩展现有实现。

论文：*De-Hallucinator: Mitigating LLM Hallucinations in Code Generation Tasks via Iterative Grounding*  
https://arxiv.org/abs/2401.01701

### Structured planning：计划必须贴近程序结构

SCoT 认为普通 CoT 偏自然语言，不适合代码；它要求模型用 sequence / branch / loop 等程序结构组织推理，在 HumanEval/MBPP 上提升 pass@1。  
对工程 prompt 的启发不是“让模型长篇思考”，而是要求它先列：

- 现有入口点
- 数据流
- validation 所在边界
- 需要修改的最小文件集合
- 不新增的东西

论文：*Structured Chain-of-Thought Prompting for Code Generation*  
https://arxiv.org/abs/2305.06599

### Semantic CoT：显式要求 data flow / control flow

SeCoT 强调代码语义信息，如数据流、控制流，比纯文本需求更能约束生成。  
适合避免重复 validation：让模型先回答“数据从哪里进入，在哪里已被校验，后续是否只需类型信任”。

论文：*Bridging Code Semantic and LLMs: Semantic Chain-of-Thought Prompting for Code Generation*  
https://arxiv.org/abs/2310.10698

### Flow engineering：把“生成”拆成理解、约束、实现、测试、修复

AlphaCodium 显示，多阶段、测试驱动、代码导向流程明显优于单次 direct prompt；GPT-4 pass@5 从 19% 提到 44%。  
工程上可落成：

1. 读现有代码和约定。
2. 写最小变更计划。
3. 明确不会新增哪些抽象。
4. 实现。
5. 运行现有测试。
6. 只基于失败修复。

论文：*Code Generation with AlphaCodium: From Prompt Engineering to Flow Engineering*  
https://arxiv.org/abs/2401.08500

### Negative constraints + scope limits

对 codegen 工具，负向约束很重要：不要新增包、不要新建抽象、不要重复 validation、不要改无关文件。它们比“写高质量代码”这种正向愿望更可执行。Cursor/Continue/Aider 都把可复用规则、约定文件或系统消息作为长期上下文，而不是每次靠用户临时提醒。Cursor Rules 文档说明规则会作为 prompt-level persistent context 注入；Continue 支持 `.continue/rules`、globs、alwaysApply；Aider 建议用只读 conventions 文件固定编码约定。  
Cursor：https://docs.cursor.com/context/rules  
Continue：https://docs.continue.dev/customize/deep-dives/rules  
Aider：https://aider.chat/docs/usage/conventions.html

## 3. 可写进 System Prompt / Steering Rules 的规则

| 规则 | 覆盖反模式 |
|---|---|
| 1. 新增任何函数、类、schema、validation、错误处理前，先搜索并复用现有同职责实现；找不到时才新增，并说明找不到的位置。 | hallucinated abstractions、重复 validation、重复实现 |
| 2. 只在 trust boundary 做完整 validation：HTTP/API 输入、外部 webhook、文件/环境变量、第三方响应。内部层传递已验证对象时不得重复 schema validation。 | defensive over-coding、跨文件 validation 漂移 |
| 3. 不为单一调用点创建 interface、factory、manager、registry、plugin、adapter，除非项目已有同模式或至少两个真实调用方需要它。 | hallucinated abstractions、over-engineering |
| 4. 不新增依赖，除非用户明确要求或现有依赖无法满足；新增前必须验证包名、维护状态、版本和项目包管理器。 | package hallucination、供应链风险 |
| 5. 错误处理遵循现有边界：不要吞异常，不要把所有错误包装成通用错误，不要在每层重复 try/catch。 | defensive over-coding、exception-handling issues |
| 6. 修改必须是最小闭环：更新所有真实调用点、类型、测试和文档引用；不得留下占位代码、伪代码或 `existing code here`。 | incomplete generation、lazy coding |
| 7. 如果需求与现有架构冲突，先指出冲突并提出最小兼容方案；不要私自引入新架构层。 | non-prompted consideration、framework violation |
| 8. 生成前列出“不会做”的范围：不改无关文件、不重命名公共 API、不迁移框架、不添加缓存/队列/权限/多租户，除非任务要求。 | scope creep、prompt-biased code |
| 9. 对 validation、权限、序列化、错误格式这类横切规则，必须找到单一 owner；如果已有多个 owner，先报告重复点，不继续复制。 | 重复 validation、DRY 违背 |
| 10. 实现后运行最相关的现有检查；如果无法运行，明确说明未验证项，不伪造测试结果。 | false confidence、隐藏失败 |

## 4. 工业工具的 Prompt 约束做法

| 工具 | 做法 | 对你的启发 |
|---|---|---|
| Aider | 支持 conventions 文件作为只读上下文；推荐把团队偏好、库选择、类型风格写成小型 markdown。还通过 diff/edit format 降低“省略代码”的 lazy coding。 | 规则要短、具体、可长期加载；编辑格式也会影响质量。 |
| Cursor | Project Rules / User Rules / AGENTS.md 作为 persistent prompt context；规则可按项目版本化。 | 把质量规则放进 repo，而不是依赖个人临时 prompt。 |
| Continue.dev | `.continue/rules` 支持 Markdown/YAML、globs、regex、alwaysApply；规则可按文件类型触发。 | 把通用规则和语言/目录专用规则拆开，减少上下文噪音。 |
| Sweep | 早期公开讨论提到用代码库检索、XML plan、文件 create/modify 列表来约束 PR；当前 Sweep 对 Salesforce 强调 grounded in live org、查询真实 schema/automation，歧义时 ask not assume。 | 对 agentic codegen，先生成“文件级计划 + 真实上下文证据”，再写代码。HN 讨论：https://news.ycombinator.com/item?id=36987454；Sweep blog：https://www.sweep.io/blog/vibe-coding-was-just-stage-one-meet-agentic-engineering/ |

## 推荐的 Steering Rule 模板

```markdown
## Code Quality Constraints for AI Codegen

- Prefer reuse over creation. Before adding a function, class, schema, validator, abstraction, or dependency, search for existing equivalents and extend the closest existing pattern.
- Keep changes minimal and task-scoped. Do not introduce new architecture, caching, retries, queues, permissions, plugins, or configuration systems unless explicitly required.
- Validate once at trust boundaries. Do not duplicate validation across controller/service/repository/client layers; pass typed/validated data inward.
- Avoid speculative abstractions. Do not create interfaces, factories, managers, adapters, registries, or strategy layers for a single use case.
- Follow existing error-handling boundaries. Do not add blanket try/catch, swallow errors, or wrap every error unless the surrounding code does so.
- Do not add new dependencies without verification. Confirm package name, version, project package manager, and existing alternatives first.
- Never hallucinate APIs. If an API, method, field, config key, or package is not present in code or official docs, treat it as unavailable.
- Complete the edit graph. Update all affected call sites, types, tests, and docs needed for the change to compile and behave consistently.
- No placeholders in implemented code. Do not leave pseudocode, commented-out attempts, or “existing code here” markers.
- Verify with the narrowest relevant tests/checks and report exactly what was and was not run.
```

核心原则可以压缩成一句：**让模型先证明“现有代码里没有更合适的落点”，再允许它新增东西。**
tokens used
67,554
## 结论先行

LLM codegen 的主要质量风险不是“写不出代码”，而是**在局部可运行的前提下制造长期维护债**：重复实现、重复 validation、过度 error handling、凭空 API/包/抽象、绕开既有架构。近两年论文也从 HumanEval 式函数正确性，转向 repo-level consistency、hallucination、design smells 和 prompt/flow engineering。

## 1. 典型反模式

| 反模式 | 表现 | 研究/实践对应 |
|---|---|---|
| Defensive over-coding | 每层都 `try/catch`、null check、schema validation；把不可能状态也写成分支；吞错或包装错误导致真实 bug 被隐藏 | AI IDE 大型项目研究发现 Exception-Handling Issues、High Complexity、Large Methods 常见；这些不是功能错误，但损害可维护性。见 *Beyond Functional Correctness*：https://arxiv.org/abs/2604.06373 |
| Hallucinated abstractions | 新建 `Manager/Service/Factory/Adapter`，但项目没有对应层次；为一次性需求抽象接口、策略、插件系统 | 同上论文报告 Code Duplication、Framework Best-Practice Violations、SRP/SoC/DRY 违背。 |
| Hallucinated APIs / objects / attributes | 调用不存在的方法、字段、类、配置项；把相似库 API 混用 | *Bugs in Large Language Models Generated Code* 归纳了 Hallucinated Object、Wrong Attribute、Wrong Input Type 等 10 类 bug：https://arxiv.org/abs/2403.08937 |
| Hallucinated dependencies | 引入不存在的 npm/PyPI 包，或使用名字相近但错误的包 | *We Have a Package for You!* 在 576,000 个样本中发现商业模型和开源模型均存在包幻觉，开源模型更严重：https://arxiv.org/abs/2406.10279 |
| 重复 validation 跨文件 | controller、service、repository、client SDK、UI form 都重复校验同一字段；规则漂移后产生不一致 | 属于 Code Duplication + Inconsistent repository-level behavior。De-Hallucinator 指出模型常不能正确复用项目已有 API，容易“变体式重复实现”：https://arxiv.org/abs/2401.01701 |
| Non-prompted consideration | 用户没要求的缓存、权限系统、多租户、重试、队列、国际化、抽象层 | *Bugs in LLM Generated Code* 明确列出 Non-Prompted Consideration 和 Prompt-biased code。 |
| Context-blind implementation | 不读现有调用点、类型、约定，直接生成孤立代码 | 2026 survey 指出 repo-level context、一致性、可靠性保证仍是关键缺口：https://link.springer.com/article/10.1007/s10489-026-07230-0 |
| Lazy coding / incomplete edit | `// existing code here`、伪代码、漏改调用点、只改 happy path | Aider 文档提到某些 edit format 会诱发模型省略大段代码，用占位注释代替真实编辑：https://aider.chat/docs/more/edit-formats.html |
| Validation bypass by tests | 写测试只覆盖自己生成的行为，避开真实 edge cases；或修改测试适配错误实现 | AlphaCodium 的结果说明单次 prompt 不足，测试驱动、多阶段 flow 显著优于单 prompt：https://arxiv.org/abs/2401.08500 |

## 2. 有效的 Prompt Engineering 技巧

### Grounding：先锚定真实代码，再生成

De-Hallucinator 的核心发现是：LLM 常生成“看起来接近”的代码，但不会正确引用项目已有 API；通过检索相关 API 参考并迭代注入 prompt，可显著减少 hallucinated API 和重复实现。  
适合写进 prompt：

> 在新增函数/类/validation 之前，必须先搜索同名、相似职责、相同 schema、相同错误处理模式；优先复用或扩展现有实现。

论文：*De-Hallucinator: Mitigating LLM Hallucinations in Code Generation Tasks via Iterative Grounding*  
https://arxiv.org/abs/2401.01701

### Structured planning：计划必须贴近程序结构

SCoT 认为普通 CoT 偏自然语言，不适合代码；它要求模型用 sequence / branch / loop 等程序结构组织推理，在 HumanEval/MBPP 上提升 pass@1。  
对工程 prompt 的启发不是“让模型长篇思考”，而是要求它先列：

- 现有入口点
- 数据流
- validation 所在边界
- 需要修改的最小文件集合
- 不新增的东西

论文：*Structured Chain-of-Thought Prompting for Code Generation*  
https://arxiv.org/abs/2305.06599

### Semantic CoT：显式要求 data flow / control flow

SeCoT 强调代码语义信息，如数据流、控制流，比纯文本需求更能约束生成。  
适合避免重复 validation：让模型先回答“数据从哪里进入，在哪里已被校验，后续是否只需类型信任”。

论文：*Bridging Code Semantic and LLMs: Semantic Chain-of-Thought Prompting for Code Generation*  
https://arxiv.org/abs/2310.10698

### Flow engineering：把“生成”拆成理解、约束、实现、测试、修复

AlphaCodium 显示，多阶段、测试驱动、代码导向流程明显优于单次 direct prompt；GPT-4 pass@5 从 19% 提到 44%。  
工程上可落成：

1. 读现有代码和约定。
2. 写最小变更计划。
3. 明确不会新增哪些抽象。
4. 实现。
5. 运行现有测试。
6. 只基于失败修复。

论文：*Code Generation with AlphaCodium: From Prompt Engineering to Flow Engineering*  
https://arxiv.org/abs/2401.08500

### Negative constraints + scope limits

对 codegen 工具，负向约束很重要：不要新增包、不要新建抽象、不要重复 validation、不要改无关文件。它们比“写高质量代码”这种正向愿望更可执行。Cursor/Continue/Aider 都把可复用规则、约定文件或系统消息作为长期上下文，而不是每次靠用户临时提醒。Cursor Rules 文档说明规则会作为 prompt-level persistent context 注入；Continue 支持 `.continue/rules`、globs、alwaysApply；Aider 建议用只读 conventions 文件固定编码约定。  
Cursor：https://docs.cursor.com/context/rules  
Continue：https://docs.continue.dev/customize/deep-dives/rules  
Aider：https://aider.chat/docs/usage/conventions.html

## 3. 可写进 System Prompt / Steering Rules 的规则

| 规则 | 覆盖反模式 |
|---|---|
| 1. 新增任何函数、类、schema、validation、错误处理前，先搜索并复用现有同职责实现；找不到时才新增，并说明找不到的位置。 | hallucinated abstractions、重复 validation、重复实现 |
| 2. 只在 trust boundary 做完整 validation：HTTP/API 输入、外部 webhook、文件/环境变量、第三方响应。内部层传递已验证对象时不得重复 schema validation。 | defensive over-coding、跨文件 validation 漂移 |
| 3. 不为单一调用点创建 interface、factory、manager、registry、plugin、adapter，除非项目已有同模式或至少两个真实调用方需要它。 | hallucinated abstractions、over-engineering |
| 4. 不新增依赖，除非用户明确要求或现有依赖无法满足；新增前必须验证包名、维护状态、版本和项目包管理器。 | package hallucination、供应链风险 |
| 5. 错误处理遵循现有边界：不要吞异常，不要把所有错误包装成通用错误，不要在每层重复 try/catch。 | defensive over-coding、exception-handling issues |
| 6. 修改必须是最小闭环：更新所有真实调用点、类型、测试和文档引用；不得留下占位代码、伪代码或 `existing code here`。 | incomplete generation、lazy coding |
| 7. 如果需求与现有架构冲突，先指出冲突并提出最小兼容方案；不要私自引入新架构层。 | non-prompted consideration、framework violation |
| 8. 生成前列出“不会做”的范围：不改无关文件、不重命名公共 API、不迁移框架、不添加缓存/队列/权限/多租户，除非任务要求。 | scope creep、prompt-biased code |
| 9. 对 validation、权限、序列化、错误格式这类横切规则，必须找到单一 owner；如果已有多个 owner，先报告重复点，不继续复制。 | 重复 validation、DRY 违背 |
| 10. 实现后运行最相关的现有检查；如果无法运行，明确说明未验证项，不伪造测试结果。 | false confidence、隐藏失败 |

## 4. 工业工具的 Prompt 约束做法

| 工具 | 做法 | 对你的启发 |
|---|---|---|
| Aider | 支持 conventions 文件作为只读上下文；推荐把团队偏好、库选择、类型风格写成小型 markdown。还通过 diff/edit format 降低“省略代码”的 lazy coding。 | 规则要短、具体、可长期加载；编辑格式也会影响质量。 |
| Cursor | Project Rules / User Rules / AGENTS.md 作为 persistent prompt context；规则可按项目版本化。 | 把质量规则放进 repo，而不是依赖个人临时 prompt。 |
| Continue.dev | `.continue/rules` 支持 Markdown/YAML、globs、regex、alwaysApply；规则可按文件类型触发。 | 把通用规则和语言/目录专用规则拆开，减少上下文噪音。 |
| Sweep | 早期公开讨论提到用代码库检索、XML plan、文件 create/modify 列表来约束 PR；当前 Sweep 对 Salesforce 强调 grounded in live org、查询真实 schema/automation，歧义时 ask not assume。 | 对 agentic codegen，先生成“文件级计划 + 真实上下文证据”，再写代码。HN 讨论：https://news.ycombinator.com/item?id=36987454；Sweep blog：https://www.sweep.io/blog/vibe-coding-was-just-stage-one-meet-agentic-engineering/ |

## 推荐的 Steering Rule 模板

```markdown
## Code Quality Constraints for AI Codegen

- Prefer reuse over creation. Before adding a function, class, schema, validator, abstraction, or dependency, search for existing equivalents and extend the closest existing pattern.
- Keep changes minimal and task-scoped. Do not introduce new architecture, caching, retries, queues, permissions, plugins, or configuration systems unless explicitly required.
- Validate once at trust boundaries. Do not duplicate validation across controller/service/repository/client layers; pass typed/validated data inward.
- Avoid speculative abstractions. Do not create interfaces, factories, managers, adapters, registries, or strategy layers for a single use case.
- Follow existing error-handling boundaries. Do not add blanket try/catch, swallow errors, or wrap every error unless the surrounding code does so.
- Do not add new dependencies without verification. Confirm package name, version, project package manager, and existing alternatives first.
- Never hallucinate APIs. If an API, method, field, config key, or package is not present in code or official docs, treat it as unavailable.
- Complete the edit graph. Update all affected call sites, types, tests, and docs needed for the change to compile and behave consistently.
- No placeholders in implemented code. Do not leave pseudocode, commented-out attempts, or “existing code here” markers.
- Verify with the narrowest relevant tests/checks and report exactly what was and was not run.
```

核心原则可以压缩成一句：**让模型先证明“现有代码里没有更合适的落点”，再允许它新增东西。**

---

# B 层：静态工具 + 复杂度阈值

Reading additional input from stdin...
OpenAI Codex v0.133.0
--------
workdir: /home/sharp/projects/kiro-workspace
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: none
reasoning summaries: none
session id: 019e524b-9d81-7e73-b0e6-e4b07a5f7129
--------
user
我要为多语言项目（Python / TypeScript / Java）配置静态代码质量检查工具，作为 CI gate（超阈值就 fail build）。请回答：1. DRY 违反 / duplicate code detection：jscpd（JS/TS）、PMD CPD（Java）、radon + flake8（Python）的能力对比 + 配置示例 + 业界推荐阈值（duplication ratio 多少算超标）。 2. Cognitive complexity vs Cyclomatic complexity：定义差异、SonarSource 提出的 cognitive complexity 度量、推荐阈值（function 级 / file 级）。 3. 代码 smell 经典理论：Fowler Refactoring 22 类 smell、哪些能被静态工具捕获、哪些需要人工 review。 4. 推荐一个'多语言代码质量工具矩阵'：每语言推荐 1-2 个工具 + 阈值表。请用中文回答，markdown 格式，附文档链接。
codex
我会先核对各工具和 SonarSource 的官方文档，避免阈值和配置项凭记忆写偏。随后按 CI gate 的可执行配置来组织答案。
web search: 
web search: jscpd documentation threshold reporters markdown config duplication threshold ...
web search: 
web search: SonarSource Cognitive Complexity white paper threshold 15 25 ...
web search: 
web search: jscpd options threshold documentation min-lines min-tokens config ...
web search: 
web search: https://pmd.github.io/pmd/pmd_userdocs_cpd.html
web search: 
web search: site:jscpd.dev/docs jscpd threshold minLines minTokens configuration ...
web search: 
web search: https://refactoring.guru/refactoring/smells
web search: 
web search: rules.sonarsource.com cognitive complexity of methods should not be too high 15 Java S3776 ...
web search: 
web search: xenon radon fail complexity threshold documentation average absolute modules ...
codex
下面按“可放进 CI gate”的角度整理。结论先说：**duplication 建议用专门 clone detector；复杂度建议按函数/方法 gate；smell 只能部分自动化，设计语义类 smell 仍需 review。**

## 1. DRY / Duplicate Code Detection

### 能力对比

| 工具 | 主要适用 | 能检测什么 | CI gate 能力 | 局限 |
|---|---|---|---|---|
| `jscpd` | JS/TS，也支持多语言 | 基于 token / 行的重复块，支持 JS、TS、Python、Java 等大量格式 | `--threshold` 超过重复率直接非 0 退出 | 偏文本/token clone，语义等价但写法不同的重复不一定抓到 |
| PMD CPD | Java 最常用，也支持多语言 | Java token 级 copy-paste；可忽略 literal / identifier / annotation | Maven `pmd:cpd-check` 默认可 fail build | 原生 gate 更偏“重复块数量/是否有 violation”，不是直接按 duplication ratio |
| `radon + flake8` | Python | `radon` 做复杂度/MI；`flake8` 做 lint + McCabe complexity | `flake8 --max-complexity` 可 fail；`radon` 建议配 `xenon` 做 fail | **不是 duplicate detector**。Python 重复代码建议用 `jscpd` 或 `pylint R0801 duplicate-code` |

`jscpd` 官方支持阈值：当前 duplication level 大于 `--threshold` 时退出错误；默认 `minTokens=50`、`minLines=5` 可调。文档：[`jscpd`](https://jscpd.dev/getting-started/introduction)、[`jscpd npm options`](https://www.npmjs.com/package/jscpd)。

PMD CPD 支持 `--minimum-tokens`，并可配置 `ignoreLiterals`、`ignoreIdentifiers`、`ignoreAnnotations`。Maven `cpd-check` 会在 violation 时 fail build。文档：[`PMD CPD`](https://pmd.github.io/pmd/pmd_userdocs_cpd.html)、[`maven-pmd-plugin cpd-check`](https://maven.apache.org/plugins/maven-pmd-plugin/cpd-check-mojo.html)。

`radon` 计算 Python cyclomatic complexity、raw metrics、maintainability index、Halstead；复杂度等级 A-F。文档：[`Radon`](https://radon.readthedocs.io/en/stable/commandline.html)。`xenon` 基于 Radon，专门用于 CI 阈值失败：[`Xenon`](https://xenon.readthedocs.io/)。

### 配置示例

#### JS/TS：`jscpd`

`.jscpd.json`

```json
{
  "path": ["src"],
  "pattern": "**/*.{js,jsx,ts,tsx}",
  "ignore": [
    "**/*.test.*",
    "**/*.spec.*",
    "**/generated/**",
    "**/dist/**"
  ],
  "minLines": 8,
  "minTokens": 80,
  "threshold": 3,
  "reporters": ["console", "html", "json"],
  "output": "reports/jscpd"
}
```

CI:

```bash
npx jscpd --config .jscpd.json
```

#### Java：PMD CPD with Maven

`pom.xml`

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-pmd-plugin</artifactId>
  <version>3.28.0</version>
  <configuration>
    <minimumTokens>100</minimumTokens>
    <ignoreLiterals>true</ignoreLiterals>
    <ignoreIdentifiers>false</ignoreIdentifiers>
    <ignoreAnnotations>true</ignoreAnnotations>
    <failOnViolation>true</failOnViolation>
    <printFailingErrors>true</printFailingErrors>
    <excludeRoots>
      <excludeRoot>target/generated-sources</excludeRoot>
    </excludeRoots>
  </configuration>
  <executions>
    <execution>
      <phase>verify</phase>
      <goals>
        <goal>cpd-check</goal>
      </goals>
    </execution>
  </executions>
</plugin>
```

CI:

```bash
mvn verify
```

#### Python：复杂度用 `flake8` / `radon`，重复代码另配 `jscpd`

`.flake8`

```ini
[flake8]
max-line-length = 100
max-complexity = 10
exclude =
    .git,
    .venv,
    build,
    dist,
    generated
```

`radon.cfg`

```ini
[radon]
exclude = tests/*,generated/*
cc_min = C
show_complexity = True
average = True
```

CI:

```bash
flake8 src tests
radon cc src -s -a
xenon src --max-absolute B --max-modules A --max-average A
npx jscpd --pattern "**/*.py" --min-lines 8 --min-tokens 80 --threshold 3 src
```

### Duplication Ratio 推荐阈值

没有跨行业统一标准，但可按 Sonar “Clean as You Code” 的实践设 gate：

| 范围 | 建议 |
|---|---|
| New code duplication `<= 3%` | 推荐 CI gate，Sonar 默认质量门常用值 |
| Whole project `<= 5%` | 健康项目目标 |
| `5% - 10%` | 需要治理，适合 warning / debt backlog |
| `> 10%` | 通常应 fail 或阻止新增重复，尤其是业务逻辑重复 |
| 单个重复块 | JS/TS/Python 建议 `minLines >= 8`、`minTokens >= 80`；Java CPD 建议 `minimumTokens >= 100` 起步 |

注意：遗留项目不要一上来按 whole project fail。更稳的做法是：**new code `<= 3%` fail gate，整体重复率用 ratchet 逐步下降**。

Sonar quality gate 常见阈值：new duplicated lines `<= 3%`，参考：[`SonarQube quality gates`](https://sonarqube.inria.fr/sonarqube/quality_gates)。

## 2. Cognitive Complexity vs Cyclomatic Complexity

### 定义差异

| 指标 | 核心问题 | 典型计算思路 | 适合衡量 |
|---|---|---|---|
| Cyclomatic Complexity | 有多少条独立执行路径？ | `if`、`for`、`while`、`case`、`catch` 等增加路径数 | 测试路径数量、分支覆盖压力 |
| Cognitive Complexity | 人读懂这段代码有多难？ | 控制流中断加分；嵌套额外加分；递归/复杂流程加分；对可读性友好的简写少惩罚 | 可维护性、理解成本、review 风险 |

ESLint 对 cyclomatic complexity 的定义是“linearly independent paths”，默认复杂度阈值是 `20`，但多数团队会把函数级 gate 设得更严：[`ESLint complexity`](https://eslint.org/docs/latest/rules/complexity)。

SonarSource 的 cognitive complexity 目标是比纯数学路径数更贴近“方法的可理解性”：[`Sonar Cognitive Complexity`](https://www.sonarsource.com/resources/cognitive-complexity/)。

### 推荐阈值

| 层级 | Cyclomatic Complexity | Cognitive Complexity | 建议 gate |
|---|---:|---:|---|
| Function / method | `<= 10` 推荐；`11-20` review；`>20` fail | `<= 15` 推荐；`16-25` review；`>25` fail | CI 应按函数/方法 fail |
| File / module | 平均 CC `<= 5`；单文件总 CC `>50` 需 review | 单文件总 cognitive `>50` review，`>100` fail 或拆分 | 文件级更适合 hotspot，不宜单独替代函数级 |
| Project | 只看趋势，不建议硬 fail | 只看趋势，不建议硬 fail | 新代码 gate + 趋势治理 |

Python Radon 的 CC 等级可直接采用：A `1-5`、B `6-10`、C `11-20`、D `21-30`、E `31-40`、F `41+`。CI 推荐 `xenon --max-absolute B`，也就是任何函数超过 B 级就 fail。

## 3. Fowler 经典 Code Smells：哪些能自动抓，哪些要 review

Martin Fowler 对 code smell 的定义是：表面迹象，通常指向系统里更深的问题；smell 本身不一定就是 bug，需要进一步判断。参考：[`Martin Fowler - Code Smell`](https://martinfowler.com/bliki/CodeSmell.html)。

Fowler / Refactoring Guru 经典 smell 分类参考：[`Refactoring Guru Code Smells`](https://refactoring.guru/refactoring/smells)。

| Smell | 静态工具可捕获程度 | 说明 |
|---|---|---|
| Duplicated Code | 高 | `jscpd`、CPD、Sonar duplication |
| Long Method | 高 | LOC、CC、Cognitive Complexity |
| Large Class | 中高 | LOC、方法数、字段数、WMC |
| Long Parameter List | 高 | ESLint / PMD / Sonar 规则 |
| Switch Statements | 中高 | 可检测 switch / if-else 链，但是否应多态化需 review |
| Comments | 中 | 可检测 TODO、注释比例、死注释；“注释是否掩盖坏设计”需人工 |
| Dead Code | 高 | ESLint、Ruff、Pyflakes、PMD、SpotBugs |
| Lazy Class | 中 | 小类/低内聚可提示，误报较多 |
| Data Class | 中 | Java POJO / DTO 可识别，但 DTO 本身未必坏 |
| Temporary Field | 中低 | 需要理解对象生命周期 |
| Message Chains | 中 | 可检测链式调用深度，但 fluent API 可能正常 |
| Middle Man | 中低 | 需要理解委托是否有价值 |
| Primitive Obsession | 低 | 需要领域建模判断 |
| Data Clumps | 中低 | 可通过重复参数组合提示 |
| Feature Envy | 中低 | 需要依赖访问模式 + 领域判断 |
| Inappropriate Intimacy | 中 | 友元、包可见、跨类访问可提示；设计判断人工 |
| Divergent Change | 低 | 需要历史变更数据 |
| Shotgun Surgery | 低 | 需要历史变更数据 |
| Parallel Inheritance Hierarchies | 中 | 结构可检测，危害需 review |
| Speculative Generality | 低 | “未来可能用”的抽象通常靠 review |
| Refused Bequest | 低 | 继承语义判断为主 |
| Alternative Classes with Different Interfaces | 低 | 需要架构/领域语义 |
| Incomplete Library Class | 人工 | 通常是第三方 API 适配问题 |

实务上：**自动工具适合抓 size、duplication、complexity、lint、显式反模式；架构意图、领域建模、变更扩散类 smell 主要靠 review 和演进数据。**

## 4. 多语言代码质量工具矩阵

| 语言 | 推荐工具 | 主要 gate | 推荐阈值 |
|---|---|---|---|
| TypeScript / JavaScript | `ESLint` + `typescript-eslint` + `eslint-plugin-sonarjs` | lint、类型相关规则、CC / cognitive complexity | `complexity <= 10`；`cognitive-complexity <= 15`；`max-depth <= 4`；`max-params <= 5` |
| TypeScript / JavaScript | `jscpd` | duplicate code | new code duplication `<= 3%`；`minLines 8`；`minTokens 80` |
| Java | `PMD` + `CPD` | code smells、copy-paste detection | CPD `minimumTokens 100`；0 new CPD violations；new duplication `<= 3%` |
| Java | `SpotBugs` 或 `SonarQube` | bug patterns、安全、maintainability | 0 new high/critical issues；method cognitive `<= 15`；method CC `<= 10` |
| Python | `Ruff` 或 `flake8` | lint、unused、style、McCabe | `max-complexity = 10`；0 new lint errors |
| Python | `radon` + `xenon` + `jscpd` | complexity + duplication | `xenon --max-absolute B --max-modules A --max-average A`；duplication `<= 3%` |

**推荐 CI gate 组合：**

```bash
# JS/TS
npx eslint .
npx jscpd --config .jscpd.json

# Java
mvn verify   # includes PMD/CPD/SpotBugs if configured

# Python
ruff check .
flake8 src tests
xenon src --max-absolute B --max-modules A --max-average A
npx jscpd --pattern "**/*.py" --threshold 3 src
```

最稳的策略是：**PR/new code 严格 gate，legacy 只记录趋势和阻止恶化**。这样不会因为历史债务让 CI 无法落地。
tokens used
60,174
下面按“可放进 CI gate”的角度整理。结论先说：**duplication 建议用专门 clone detector；复杂度建议按函数/方法 gate；smell 只能部分自动化，设计语义类 smell 仍需 review。**

## 1. DRY / Duplicate Code Detection

### 能力对比

| 工具 | 主要适用 | 能检测什么 | CI gate 能力 | 局限 |
|---|---|---|---|---|
| `jscpd` | JS/TS，也支持多语言 | 基于 token / 行的重复块，支持 JS、TS、Python、Java 等大量格式 | `--threshold` 超过重复率直接非 0 退出 | 偏文本/token clone，语义等价但写法不同的重复不一定抓到 |
| PMD CPD | Java 最常用，也支持多语言 | Java token 级 copy-paste；可忽略 literal / identifier / annotation | Maven `pmd:cpd-check` 默认可 fail build | 原生 gate 更偏“重复块数量/是否有 violation”，不是直接按 duplication ratio |
| `radon + flake8` | Python | `radon` 做复杂度/MI；`flake8` 做 lint + McCabe complexity | `flake8 --max-complexity` 可 fail；`radon` 建议配 `xenon` 做 fail | **不是 duplicate detector**。Python 重复代码建议用 `jscpd` 或 `pylint R0801 duplicate-code` |

`jscpd` 官方支持阈值：当前 duplication level 大于 `--threshold` 时退出错误；默认 `minTokens=50`、`minLines=5` 可调。文档：[`jscpd`](https://jscpd.dev/getting-started/introduction)、[`jscpd npm options`](https://www.npmjs.com/package/jscpd)。

PMD CPD 支持 `--minimum-tokens`，并可配置 `ignoreLiterals`、`ignoreIdentifiers`、`ignoreAnnotations`。Maven `cpd-check` 会在 violation 时 fail build。文档：[`PMD CPD`](https://pmd.github.io/pmd/pmd_userdocs_cpd.html)、[`maven-pmd-plugin cpd-check`](https://maven.apache.org/plugins/maven-pmd-plugin/cpd-check-mojo.html)。

`radon` 计算 Python cyclomatic complexity、raw metrics、maintainability index、Halstead；复杂度等级 A-F。文档：[`Radon`](https://radon.readthedocs.io/en/stable/commandline.html)。`xenon` 基于 Radon，专门用于 CI 阈值失败：[`Xenon`](https://xenon.readthedocs.io/)。

### 配置示例

#### JS/TS：`jscpd`

`.jscpd.json`

```json
{
  "path": ["src"],
  "pattern": "**/*.{js,jsx,ts,tsx}",
  "ignore": [
    "**/*.test.*",
    "**/*.spec.*",
    "**/generated/**",
    "**/dist/**"
  ],
  "minLines": 8,
  "minTokens": 80,
  "threshold": 3,
  "reporters": ["console", "html", "json"],
  "output": "reports/jscpd"
}
```

CI:

```bash
npx jscpd --config .jscpd.json
```

#### Java：PMD CPD with Maven

`pom.xml`

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-pmd-plugin</artifactId>
  <version>3.28.0</version>
  <configuration>
    <minimumTokens>100</minimumTokens>
    <ignoreLiterals>true</ignoreLiterals>
    <ignoreIdentifiers>false</ignoreIdentifiers>
    <ignoreAnnotations>true</ignoreAnnotations>
    <failOnViolation>true</failOnViolation>
    <printFailingErrors>true</printFailingErrors>
    <excludeRoots>
      <excludeRoot>target/generated-sources</excludeRoot>
    </excludeRoots>
  </configuration>
  <executions>
    <execution>
      <phase>verify</phase>
      <goals>
        <goal>cpd-check</goal>
      </goals>
    </execution>
  </executions>
</plugin>
```

CI:

```bash
mvn verify
```

#### Python：复杂度用 `flake8` / `radon`，重复代码另配 `jscpd`

`.flake8`

```ini
[flake8]
max-line-length = 100
max-complexity = 10
exclude =
    .git,
    .venv,
    build,
    dist,
    generated
```

`radon.cfg`

```ini
[radon]
exclude = tests/*,generated/*
cc_min = C
show_complexity = True
average = True
```

CI:

```bash
flake8 src tests
radon cc src -s -a
xenon src --max-absolute B --max-modules A --max-average A
npx jscpd --pattern "**/*.py" --min-lines 8 --min-tokens 80 --threshold 3 src
```

### Duplication Ratio 推荐阈值

没有跨行业统一标准，但可按 Sonar “Clean as You Code” 的实践设 gate：

| 范围 | 建议 |
|---|---|
| New code duplication `<= 3%` | 推荐 CI gate，Sonar 默认质量门常用值 |
| Whole project `<= 5%` | 健康项目目标 |
| `5% - 10%` | 需要治理，适合 warning / debt backlog |
| `> 10%` | 通常应 fail 或阻止新增重复，尤其是业务逻辑重复 |
| 单个重复块 | JS/TS/Python 建议 `minLines >= 8`、`minTokens >= 80`；Java CPD 建议 `minimumTokens >= 100` 起步 |

注意：遗留项目不要一上来按 whole project fail。更稳的做法是：**new code `<= 3%` fail gate，整体重复率用 ratchet 逐步下降**。

Sonar quality gate 常见阈值：new duplicated lines `<= 3%`，参考：[`SonarQube quality gates`](https://sonarqube.inria.fr/sonarqube/quality_gates)。

## 2. Cognitive Complexity vs Cyclomatic Complexity

### 定义差异

| 指标 | 核心问题 | 典型计算思路 | 适合衡量 |
|---|---|---|---|
| Cyclomatic Complexity | 有多少条独立执行路径？ | `if`、`for`、`while`、`case`、`catch` 等增加路径数 | 测试路径数量、分支覆盖压力 |
| Cognitive Complexity | 人读懂这段代码有多难？ | 控制流中断加分；嵌套额外加分；递归/复杂流程加分；对可读性友好的简写少惩罚 | 可维护性、理解成本、review 风险 |

ESLint 对 cyclomatic complexity 的定义是“linearly independent paths”，默认复杂度阈值是 `20`，但多数团队会把函数级 gate 设得更严：[`ESLint complexity`](https://eslint.org/docs/latest/rules/complexity)。

SonarSource 的 cognitive complexity 目标是比纯数学路径数更贴近“方法的可理解性”：[`Sonar Cognitive Complexity`](https://www.sonarsource.com/resources/cognitive-complexity/)。

### 推荐阈值

| 层级 | Cyclomatic Complexity | Cognitive Complexity | 建议 gate |
|---|---:|---:|---|
| Function / method | `<= 10` 推荐；`11-20` review；`>20` fail | `<= 15` 推荐；`16-25` review；`>25` fail | CI 应按函数/方法 fail |
| File / module | 平均 CC `<= 5`；单文件总 CC `>50` 需 review | 单文件总 cognitive `>50` review，`>100` fail 或拆分 | 文件级更适合 hotspot，不宜单独替代函数级 |
| Project | 只看趋势，不建议硬 fail | 只看趋势，不建议硬 fail | 新代码 gate + 趋势治理 |

Python Radon 的 CC 等级可直接采用：A `1-5`、B `6-10`、C `11-20`、D `21-30`、E `31-40`、F `41+`。CI 推荐 `xenon --max-absolute B`，也就是任何函数超过 B 级就 fail。

## 3. Fowler 经典 Code Smells：哪些能自动抓，哪些要 review

Martin Fowler 对 code smell 的定义是：表面迹象，通常指向系统里更深的问题；smell 本身不一定就是 bug，需要进一步判断。参考：[`Martin Fowler - Code Smell`](https://martinfowler.com/bliki/CodeSmell.html)。

Fowler / Refactoring Guru 经典 smell 分类参考：[`Refactoring Guru Code Smells`](https://refactoring.guru/refactoring/smells)。

| Smell | 静态工具可捕获程度 | 说明 |
|---|---|---|
| Duplicated Code | 高 | `jscpd`、CPD、Sonar duplication |
| Long Method | 高 | LOC、CC、Cognitive Complexity |
| Large Class | 中高 | LOC、方法数、字段数、WMC |
| Long Parameter List | 高 | ESLint / PMD / Sonar 规则 |
| Switch Statements | 中高 | 可检测 switch / if-else 链，但是否应多态化需 review |
| Comments | 中 | 可检测 TODO、注释比例、死注释；“注释是否掩盖坏设计”需人工 |
| Dead Code | 高 | ESLint、Ruff、Pyflakes、PMD、SpotBugs |
| Lazy Class | 中 | 小类/低内聚可提示，误报较多 |
| Data Class | 中 | Java POJO / DTO 可识别，但 DTO 本身未必坏 |
| Temporary Field | 中低 | 需要理解对象生命周期 |
| Message Chains | 中 | 可检测链式调用深度，但 fluent API 可能正常 |
| Middle Man | 中低 | 需要理解委托是否有价值 |
| Primitive Obsession | 低 | 需要领域建模判断 |
| Data Clumps | 中低 | 可通过重复参数组合提示 |
| Feature Envy | 中低 | 需要依赖访问模式 + 领域判断 |
| Inappropriate Intimacy | 中 | 友元、包可见、跨类访问可提示；设计判断人工 |
| Divergent Change | 低 | 需要历史变更数据 |
| Shotgun Surgery | 低 | 需要历史变更数据 |
| Parallel Inheritance Hierarchies | 中 | 结构可检测，危害需 review |
| Speculative Generality | 低 | “未来可能用”的抽象通常靠 review |
| Refused Bequest | 低 | 继承语义判断为主 |
| Alternative Classes with Different Interfaces | 低 | 需要架构/领域语义 |
| Incomplete Library Class | 人工 | 通常是第三方 API 适配问题 |

实务上：**自动工具适合抓 size、duplication、complexity、lint、显式反模式；架构意图、领域建模、变更扩散类 smell 主要靠 review 和演进数据。**

## 4. 多语言代码质量工具矩阵

| 语言 | 推荐工具 | 主要 gate | 推荐阈值 |
|---|---|---|---|
| TypeScript / JavaScript | `ESLint` + `typescript-eslint` + `eslint-plugin-sonarjs` | lint、类型相关规则、CC / cognitive complexity | `complexity <= 10`；`cognitive-complexity <= 15`；`max-depth <= 4`；`max-params <= 5` |
| TypeScript / JavaScript | `jscpd` | duplicate code | new code duplication `<= 3%`；`minLines 8`；`minTokens 80` |
| Java | `PMD` + `CPD` | code smells、copy-paste detection | CPD `minimumTokens 100`；0 new CPD violations；new duplication `<= 3%` |
| Java | `SpotBugs` 或 `SonarQube` | bug patterns、安全、maintainability | 0 new high/critical issues；method cognitive `<= 15`；method CC `<= 10` |
| Python | `Ruff` 或 `flake8` | lint、unused、style、McCabe | `max-complexity = 10`；0 new lint errors |
| Python | `radon` + `xenon` + `jscpd` | complexity + duplication | `xenon --max-absolute B --max-modules A --max-average A`；duplication `<= 3%` |

**推荐 CI gate 组合：**

```bash
# JS/TS
npx eslint .
npx jscpd --config .jscpd.json

# Java
mvn verify   # includes PMD/CPD/SpotBugs if configured

# Python
ruff check .
flake8 src tests
xenon src --max-absolute B --max-modules A --max-average A
npx jscpd --pattern "**/*.py" --threshold 3 src
```

最稳的策略是：**PR/new code 严格 gate，legacy 只记录趋势和阻止恶化**。这样不会因为历史债务让 CI 无法落地。

---

# C 层：LLM-as-judge Review Agent

Reading additional input from stdin...
OpenAI Codex v0.133.0
--------
workdir: /home/sharp/projects/kiro-workspace
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: none
reasoning summaries: none
session id: 019e524d-8c27-7810-955b-5cd57283c3ec
--------
user
我要做一个 LLM 驱动的 code review agent，专门审 AI 生成的代码（找静态工具抓不到的语义重复 / 设计问题）。请回答：1. LLM-as-judge 近期研究（2024-2026）：关键论文（NeurIPS / ICSE / FSE / arxiv），他们怎么衡量 LLM judge 的可靠性？ 2. 自动 code review 的工业实践：CodeRabbit / Sweep / Aider 的 review 模式，他们 prompt 怎么写？ 3. 设计一个 reviewer agent 的核心 prompt（中文）：让它专门找'语义重复 / 跨文件重复 validation / 过度抽象 / 防御性过度'。 4. reviewer 的 output 格式建议（让 user 5 分钟内能读完 + decide）。请用中文回答，markdown 格式。
codex
我会先查近两年的论文和公开项目资料，优先用论文、官方文档和开源仓库里的 prompt/配置；CodeRabbit 这类闭源产品如果没有完整 prompt，我会明确区分“公开可见配置/行为”和推断。
web search: 
web search: 2024 LLM-as-a-judge reliability benchmark human agreement arxiv ...
web search: 
web search: LLM-as-a-Judge empirical study reliability Cohen kappa Spearman Kendall human agreement 2024 arxiv ...
web search: 
web search: CodeRabbit prompt code review system prompt ...
web search: 
web search: site:github.com/sweepai/sweep review prompt ...
web search: 
web search: https://github.com/sweepai/sweep/tree/main/sweepai/core
web search: 
web search: https://github.com/Aider-AI/aider/blob/main/aider/coders/ask_prompts.py
web search: 
web search: https://raw.githubusercontent.com/Aider-AI/aider/main/aider/coders/ask_prompts.py
web search: 
web search: CodeRabbit custom review instructions coderabbit.yaml path instructions review profile ...
web search: 
web search: github.com/sweepai/sweep "review_prompts.py" "review_prompt" ...
web search: 
web search: ICSE 2024 automated code review ChatGPT code review empirical study ...
codex
截至 **2026-05-23**，我会把这个方向拆成两层：LLM judge 研究主要回答“模型评分/判断能不能信”；code review agent 工程上要回答“如何让输出足够少、证据足够硬、误报可控”。

## 1. LLM-as-Judge 近期研究：可靠性怎么衡量

| 论文 / 方向 | 重点 | 可靠性衡量方式 |
|---|---|---|
| **Judging LLM-as-a-Judge**，NeurIPS Datasets & Benchmarks 2023，仍是后续 2024-2026 的基础参照 | 比较 GPT-4 judge 与人类偏好的一致性 | 人类一致率、pairwise agreement、位置偏差、verbosity bias、自增强偏差等。论文强调 judge 不能只看“看起来合理”，要看与人类 gold standard 的一致性。[来源](https://proceedings.neurips.cc/paper_files/paper/2023/file/91f18a1287b398d378ef22505bf41832-Paper-Datasets_and_Benchmarks.pdf) |
| **Fine-tuned Judge Model is not a General Substitute for GPT-4**，arXiv 2024 / ACL Findings 2025 | 细调 judge 在域内强，但泛化、公平性、细粒度维度上弱 | 用 in-domain / out-of-domain benchmark 对比 GPT-4 与 fine-tuned judge；看 accuracy、泛化能力、公平性、aspect-specific evaluation、成本。[来源](https://arxiv.org/abs/2403.02839) |
| **Prometheus 2**，arXiv 2024 | 开源 evaluator LM，主打 rubric-based 评分和 pairwise ranking | 在 direct assessment 和 pairwise ranking benchmark 上，与人类和 proprietary judge 的相关性/一致性比较。[来源](https://arxiv.org/abs/2405.01535) |
| **LLM Evaluators Recognize and Favor Their Own Generations**，NeurIPS 2024 | judge 会偏爱自己模型生成的答案 | 控制不同模型输出质量相近时，观察 evaluator 是否系统性偏向自身输出；这是你做 code review agent 时要警惕的“自家模型审自家代码”问题。[来源](https://proceedings.neurips.cc/paper_files/paper/2024/hash/7f1f0218e45f5414c79c0679633e47bc-Abstract-Conference.html) |
| **Judging the Judges: Position Bias in LLM-as-a-Judge**，arXiv 2024 | pairwise judge 对 A/B 顺序敏感 | 交换候选答案顺序，测量选择翻转率、position bias、跨模型一致性；实验覆盖 MTBench、DevBench、大量评估实例。[来源](https://arxiv.org/abs/2406.07791) |
| **JudgeBench**，arXiv 2024 | 用客观正确性构造更难的 judge benchmark | 从知识、推理、数学、代码等任务构造 response pairs，用 objective labels 而不只依赖 crowd preference；发现 GPT-4o 等强 judge 在困难样本上接近随机。[来源](https://arxiv.org/abs/2410.12784) |
| **Large Language Models are Inconsistent and Biased Evaluators**，arXiv 2024 | judge 对 prompt、采样、格式非常敏感 | 测 inter-sample agreement、prompt sensitivity、bias；结论是零样本 evaluator 不稳定。[来源](https://arxiv.gg/abs/2405.01724) |
| **Black-box Uncertainty Quantification Method for LLM-as-a-Judge**，NeurIPS 2024 workshop | 不只给分，还估计 judge 的不确定性 | 用评分 token 概率、交叉评估关系、confusion matrix 推导 uncertainty label，并验证 uncertainty 与 judge accuracy 的相关性。[来源](https://neurips.cc/virtual/2024/105605) |
| **MCTS-Judge**，arXiv 2025 | 面向代码正确性评估，用 test-time scaling 提高 judge 推理可靠性 | 在代码正确性 benchmark 上比较 base judge、o1 系列、MCTS judge 的 accuracy/token cost；报告 base 从 41% 提升到 80%。[来源](https://arxiv.org/abs/2502.12468) |
| **LLMs Cannot Reliably Judge (Yet?): RobustJudge**，arXiv 2025 | 系统测鲁棒性 | 用扰动、对抗样本、prompt variation、格式变化测 judge 是否稳定。[来源](https://arxiv.org/abs/2506.09443) |
| **Are LLMs Reliable Code Reviewers?**，arXiv 2026 | 专门看 LLM 是否会过度修正满足需求的代码 | 用 requirement conformance 判断任务，比较原实现和模型建议修复；发现要求解释/给修复反而可能提高误判率，并提出 fix-guided verification filter。[来源](https://arxiv.org/abs/2603.00539) |

对你的 reviewer agent 最有用的指标不是单一 accuracy，而是：

- **与人类 reviewer 一致性**：Cohen’s kappa、Krippendorff’s alpha、pairwise agreement。
- **排序/打分相关性**：Spearman、Kendall、Pearson，适合多候选代码质量排序。
- **位置/格式鲁棒性**：交换 diff 顺序、文件顺序、候选 A/B 顺序后是否翻转。
- **自一致性**：同一输入多次采样，finding 是否稳定。
- **误报成本**：false positive per KLOC、每 PR 可读 finding 数、被开发者采纳率。
- **可验证性**：每条 finding 是否有文件/行号/重复证据/反例/最小修复建议。
- **不确定性校准**：高置信 finding 是否真的更可能被人类接受。
- **防自偏差**：不要用同一模型“生成代码 + 审自己代码”作为唯一 gate。

## 2. 自动 code review 工业实践：CodeRabbit / Sweep / Aider

### CodeRabbit

CodeRabbit 的完整系统 prompt 没有公开，但它的公开文档能看出工程形态：

- 用 `.coderabbit.yaml` 做版本化配置，优先级高于 UI 配置。[来源](https://docs.coderabbit.ai/getting-started/configure-coderabbit/)
- 支持 `reviews.instructions`、`reviews.path_instructions`、review profile、path filters、工具集成、code guidelines。[来源](https://docs.coderabbit.ai/reference/configuration/)
- CLI 支持 `cr --plain`、`cr --prompt-only`，并建议 agent 运行 review 后“只修 major/critical，忽略 nits”，再二次 review 防回归。[来源](https://docs.coderabbit.ai/cli/index)
- Claude 插件页面称其结合 40+ analyzers、AST parsing、codegraph、项目 guideline，并按 Critical / Suggestions / Positive feedback 组织结果。[来源](https://claude.com/plugins/coderabbit)

可以推断它的 prompt 策略是：**静态分析 + code graph + repo guideline + diff review + severity gating**，而不是纯“把 diff 丢给模型”。

对你有用的借鉴：

```yaml
reviews:
  profile: assertive
  instructions: |
    Focus on semantic duplication, duplicated validation, unnecessary abstraction,
    and defensive code that hides invariants. Ignore style-only comments.
  path_instructions:
    - path: "src/**"
      instructions: "Compare new validation with existing domain/service validators before flagging."
```

### Sweep

Sweep 早期是开源 GitHub issue-to-PR agent，现在官方定位更偏 JetBrains coding agent。它的公开文档强调 Agent、Inline Editing、AI Commit Messages、Code Review。[来源](https://docs.sweep.dev/)

可公开确认的点：

- 早期 repo 里存在 `review_prompts.py`、`pull_request_bot.py`、`pr_reader.py` 等模块，说明它把 PR 读取、review prompt、上下文选择拆开做。[来源](https://github.com/sweepai/sweep/tree/main/sweepai/core)
- 公开资料不足以恢复当前 Sweep 产品的完整 review prompt。
- 它更像“开发 agent + review/修复循环”，而不是独立 judge。

对你有用的借鉴是流程，而不是 prompt 原文：

1. 先读取 PR diff、commit message、相关文件。
2. 生成 review comments。
3. 评论要能转成可执行修复任务。
4. 对大 diff 做上下文裁剪，避免 full-context attention dilution。

### Aider

Aider 不是专门的 code review SaaS，但它的 review/ask 模式很值得学：

- `ask` 模式只回答代码问题，不改文件；`code` 模式才改；`architect` 模式分离规划和编辑。[来源](https://aider.chat/docs/usage/modes.html)
- `/ask`、`/add`、`/context` 等命令允许用户控制上下文。[来源](https://aider.chat/docs/usage/commands.html)
- 源码里的 ask prompt 核心是“expert code analyst，回答 supplied code，必要时简短描述变更，不返回完整 diff”。[来源](https://github.com/Aider-AI/aider/blob/main/aider/coders/ask_prompts.py)
- base prompt 强调“注意用户请求范围，不要修改无关代码”。[来源](https://github.com/Aider-AI/aider/blob/main/aider/coders/base_prompts.py)

对你有用的借鉴：review agent 应默认 **只审不改**，并且强约束“不要顺手重构”。

## 3. Reviewer Agent 核心 Prompt（中文）

下面是一个可直接作为 system/developer prompt 的版本。

```markdown
你是一个专门审查 AI 生成代码的 code review agent。你的目标不是替代 linter、formatter、type checker、SAST 或测试，而是发现这些工具通常抓不到的语义级设计问题。

## 审查重点

只重点寻找以下四类问题：

1. 语义重复
   - 新增代码与既有函数、服务、hook、validator、mapper、policy、schema 做了同一件事。
   - 名字不同但业务规则、数据转换、状态机、权限判断、错误处理语义相同或高度重叠。
   - AI 生成了“看起来局部合理”的新逻辑，但项目里已有等价抽象。

2. 跨文件重复 validation
   - 同一字段、请求、权限、状态、边界条件在 controller / service / UI / schema / test helper 中重复校验。
   - 新增 validation 与现有 source of truth 不一致，可能造成 drift。
   - 应优先指出“哪个文件应该是唯一规则来源”，而不是机械建议“抽 helper”。

3. 过度抽象
   - 为一次性需求引入 framework、manager、factory、strategy、registry、adapter、base class、generic type 等。
   - 抽象没有两个以上真实调用方，或者隐藏了比它减少的重复更多的复杂度。
   - 命名泛化但业务边界不清，未来改动会被迫理解间接层。

4. 防御性过度
   - 对内部不变量反复做 null/undefined/type/range 检查，掩盖上游契约不清。
   - catch 后吞错、fallback 默认值、optional chaining、空数组兜底让错误静默。
   - 增加“不可能发生”的分支，却没有说明来源、恢复策略或观测信号。

## 审查方法

先理解变更意图，再比较新增代码与既有代码。不要只看 diff 中的新增行；必须考虑调用路径、已有模块职责和项目约定。

每条 finding 必须满足：
- 有具体文件和位置。
- 有至少一个证据：相似逻辑位置、重复规则、现有抽象、调用链或不变量来源。
- 说明为什么这是实际维护风险，而不是风格偏好。
- 给出最小修复方向。
- 标注置信度：High / Medium / Low。
- 如果证据不足，降级为“需要确认”，不要写成确定问题。

## 不要做

- 不报告格式、命名、import 顺序、lint、简单性能微优化。
- 不泛泛建议“提高可读性”“增加注释”“抽象成公共函数”。
- 不因为代码长就说它需要拆分；必须指出具体重复语义或职责泄漏。
- 不建议大重构，除非当前变更已经引入明确设计债。
- 不输出超过 5 条 finding。没有高价值问题时，明确说“未发现值得阻塞的语义级问题”。

## 严重程度

- Blocker：会导致业务规则分叉、权限/validation 不一致、错误被静默吞掉，或明显破坏既有架构边界。
- High：短期可工作，但会让后续改动很容易改漏、重复修复或产生行为漂移。
- Medium：设计上偏重或重复，但影响范围有限。
- Low：只作为可选提醒，不应阻塞合并。

## 输出要求

用中文输出。先给决策摘要，再列 findings。每条 finding 控制在 120 字以内，必要时附一行“建议”。最后给一个 3 项以内的验证清单。
```

## 4. Output 格式建议：5 分钟内读完并决定

建议输出永远固定为四块：**结论、阻塞项、高信号建议、验证清单**。最多 5 条 finding。

```markdown
## Review 结论

建议：Request changes / Approve with comments / Approve

风险摘要：本次变更主要风险是 <一句话>。
发现数量：Blocker 1，High 2，Medium 1。

## 必须处理

### 1. [Blocker] validation 规则在 API 与 service 分叉
位置：`src/api/user.ts:42`，`src/domain/userPolicy.ts:18`
问题：新增 email 状态校验重复了 `userPolicy.canInvite` 的部分规则，但漏掉 suspended user。
影响：后续修改邀请规则时容易只改一处，产生权限漂移。
建议：让 API 调用现有 policy，或把新增规则并入 policy。
置信度：High

## 建议处理

### 2. [High] 一次性 factory 增加了不必要间接层
位置：`src/payments/providerFactory.ts:1`
问题：当前只有 Stripe 一个调用方，factory 没有隔离变化点，反而隐藏初始化参数。
建议：先内联到调用点；等第二个 provider 出现再抽象。
置信度：Medium

## 需要确认

- `src/forms/validate.ts` 与 `src/schema/user.ts` 的 age 规则看起来重复，但我没有看到 schema 是否用于运行时校验。请确认 source of truth。

## 验证清单

- 修改后跑现有 validation / policy 单测。
- 搜索同一业务规则是否仍有第二份实现。
- 确认没有用 fallback 或 catch 吞掉应暴露的契约错误。
```

我建议产品上再加两个硬限制：

- **默认少说**：超过 5 条 finding 自动只保留 Blocker/High；nits 永不输出。
- **证据优先**：没有跨文件证据的 finding 不进入主列表，只能进“需要确认”。
- **可采纳率作为核心指标**：不要优化“发现更多问题”，优化“人类 5 分钟内能决定且愿意采纳”。
tokens used
83,648
截至 **2026-05-23**，我会把这个方向拆成两层：LLM judge 研究主要回答“模型评分/判断能不能信”；code review agent 工程上要回答“如何让输出足够少、证据足够硬、误报可控”。

## 1. LLM-as-Judge 近期研究：可靠性怎么衡量

| 论文 / 方向 | 重点 | 可靠性衡量方式 |
|---|---|---|
| **Judging LLM-as-a-Judge**，NeurIPS Datasets & Benchmarks 2023，仍是后续 2024-2026 的基础参照 | 比较 GPT-4 judge 与人类偏好的一致性 | 人类一致率、pairwise agreement、位置偏差、verbosity bias、自增强偏差等。论文强调 judge 不能只看“看起来合理”，要看与人类 gold standard 的一致性。[来源](https://proceedings.neurips.cc/paper_files/paper/2023/file/91f18a1287b398d378ef22505bf41832-Paper-Datasets_and_Benchmarks.pdf) |
| **Fine-tuned Judge Model is not a General Substitute for GPT-4**，arXiv 2024 / ACL Findings 2025 | 细调 judge 在域内强，但泛化、公平性、细粒度维度上弱 | 用 in-domain / out-of-domain benchmark 对比 GPT-4 与 fine-tuned judge；看 accuracy、泛化能力、公平性、aspect-specific evaluation、成本。[来源](https://arxiv.org/abs/2403.02839) |
| **Prometheus 2**，arXiv 2024 | 开源 evaluator LM，主打 rubric-based 评分和 pairwise ranking | 在 direct assessment 和 pairwise ranking benchmark 上，与人类和 proprietary judge 的相关性/一致性比较。[来源](https://arxiv.org/abs/2405.01535) |
| **LLM Evaluators Recognize and Favor Their Own Generations**，NeurIPS 2024 | judge 会偏爱自己模型生成的答案 | 控制不同模型输出质量相近时，观察 evaluator 是否系统性偏向自身输出；这是你做 code review agent 时要警惕的“自家模型审自家代码”问题。[来源](https://proceedings.neurips.cc/paper_files/paper/2024/hash/7f1f0218e45f5414c79c0679633e47bc-Abstract-Conference.html) |
| **Judging the Judges: Position Bias in LLM-as-a-Judge**，arXiv 2024 | pairwise judge 对 A/B 顺序敏感 | 交换候选答案顺序，测量选择翻转率、position bias、跨模型一致性；实验覆盖 MTBench、DevBench、大量评估实例。[来源](https://arxiv.org/abs/2406.07791) |
| **JudgeBench**，arXiv 2024 | 用客观正确性构造更难的 judge benchmark | 从知识、推理、数学、代码等任务构造 response pairs，用 objective labels 而不只依赖 crowd preference；发现 GPT-4o 等强 judge 在困难样本上接近随机。[来源](https://arxiv.org/abs/2410.12784) |
| **Large Language Models are Inconsistent and Biased Evaluators**，arXiv 2024 | judge 对 prompt、采样、格式非常敏感 | 测 inter-sample agreement、prompt sensitivity、bias；结论是零样本 evaluator 不稳定。[来源](https://arxiv.gg/abs/2405.01724) |
| **Black-box Uncertainty Quantification Method for LLM-as-a-Judge**，NeurIPS 2024 workshop | 不只给分，还估计 judge 的不确定性 | 用评分 token 概率、交叉评估关系、confusion matrix 推导 uncertainty label，并验证 uncertainty 与 judge accuracy 的相关性。[来源](https://neurips.cc/virtual/2024/105605) |
| **MCTS-Judge**，arXiv 2025 | 面向代码正确性评估，用 test-time scaling 提高 judge 推理可靠性 | 在代码正确性 benchmark 上比较 base judge、o1 系列、MCTS judge 的 accuracy/token cost；报告 base 从 41% 提升到 80%。[来源](https://arxiv.org/abs/2502.12468) |
| **LLMs Cannot Reliably Judge (Yet?): RobustJudge**，arXiv 2025 | 系统测鲁棒性 | 用扰动、对抗样本、prompt variation、格式变化测 judge 是否稳定。[来源](https://arxiv.org/abs/2506.09443) |
| **Are LLMs Reliable Code Reviewers?**，arXiv 2026 | 专门看 LLM 是否会过度修正满足需求的代码 | 用 requirement conformance 判断任务，比较原实现和模型建议修复；发现要求解释/给修复反而可能提高误判率，并提出 fix-guided verification filter。[来源](https://arxiv.org/abs/2603.00539) |

对你的 reviewer agent 最有用的指标不是单一 accuracy，而是：

- **与人类 reviewer 一致性**：Cohen’s kappa、Krippendorff’s alpha、pairwise agreement。
- **排序/打分相关性**：Spearman、Kendall、Pearson，适合多候选代码质量排序。
- **位置/格式鲁棒性**：交换 diff 顺序、文件顺序、候选 A/B 顺序后是否翻转。
- **自一致性**：同一输入多次采样，finding 是否稳定。
- **误报成本**：false positive per KLOC、每 PR 可读 finding 数、被开发者采纳率。
- **可验证性**：每条 finding 是否有文件/行号/重复证据/反例/最小修复建议。
- **不确定性校准**：高置信 finding 是否真的更可能被人类接受。
- **防自偏差**：不要用同一模型“生成代码 + 审自己代码”作为唯一 gate。

## 2. 自动 code review 工业实践：CodeRabbit / Sweep / Aider

### CodeRabbit

CodeRabbit 的完整系统 prompt 没有公开，但它的公开文档能看出工程形态：

- 用 `.coderabbit.yaml` 做版本化配置，优先级高于 UI 配置。[来源](https://docs.coderabbit.ai/getting-started/configure-coderabbit/)
- 支持 `reviews.instructions`、`reviews.path_instructions`、review profile、path filters、工具集成、code guidelines。[来源](https://docs.coderabbit.ai/reference/configuration/)
- CLI 支持 `cr --plain`、`cr --prompt-only`，并建议 agent 运行 review 后“只修 major/critical，忽略 nits”，再二次 review 防回归。[来源](https://docs.coderabbit.ai/cli/index)
- Claude 插件页面称其结合 40+ analyzers、AST parsing、codegraph、项目 guideline，并按 Critical / Suggestions / Positive feedback 组织结果。[来源](https://claude.com/plugins/coderabbit)

可以推断它的 prompt 策略是：**静态分析 + code graph + repo guideline + diff review + severity gating**，而不是纯“把 diff 丢给模型”。

对你有用的借鉴：

```yaml
reviews:
  profile: assertive
  instructions: |
    Focus on semantic duplication, duplicated validation, unnecessary abstraction,
    and defensive code that hides invariants. Ignore style-only comments.
  path_instructions:
    - path: "src/**"
      instructions: "Compare new validation with existing domain/service validators before flagging."
```

### Sweep

Sweep 早期是开源 GitHub issue-to-PR agent，现在官方定位更偏 JetBrains coding agent。它的公开文档强调 Agent、Inline Editing、AI Commit Messages、Code Review。[来源](https://docs.sweep.dev/)

可公开确认的点：

- 早期 repo 里存在 `review_prompts.py`、`pull_request_bot.py`、`pr_reader.py` 等模块，说明它把 PR 读取、review prompt、上下文选择拆开做。[来源](https://github.com/sweepai/sweep/tree/main/sweepai/core)
- 公开资料不足以恢复当前 Sweep 产品的完整 review prompt。
- 它更像“开发 agent + review/修复循环”，而不是独立 judge。

对你有用的借鉴是流程，而不是 prompt 原文：

1. 先读取 PR diff、commit message、相关文件。
2. 生成 review comments。
3. 评论要能转成可执行修复任务。
4. 对大 diff 做上下文裁剪，避免 full-context attention dilution。

### Aider

Aider 不是专门的 code review SaaS，但它的 review/ask 模式很值得学：

- `ask` 模式只回答代码问题，不改文件；`code` 模式才改；`architect` 模式分离规划和编辑。[来源](https://aider.chat/docs/usage/modes.html)
- `/ask`、`/add`、`/context` 等命令允许用户控制上下文。[来源](https://aider.chat/docs/usage/commands.html)
- 源码里的 ask prompt 核心是“expert code analyst，回答 supplied code，必要时简短描述变更，不返回完整 diff”。[来源](https://github.com/Aider-AI/aider/blob/main/aider/coders/ask_prompts.py)
- base prompt 强调“注意用户请求范围，不要修改无关代码”。[来源](https://github.com/Aider-AI/aider/blob/main/aider/coders/base_prompts.py)

对你有用的借鉴：review agent 应默认 **只审不改**，并且强约束“不要顺手重构”。

## 3. Reviewer Agent 核心 Prompt（中文）

下面是一个可直接作为 system/developer prompt 的版本。

```markdown
你是一个专门审查 AI 生成代码的 code review agent。你的目标不是替代 linter、formatter、type checker、SAST 或测试，而是发现这些工具通常抓不到的语义级设计问题。

## 审查重点

只重点寻找以下四类问题：

1. 语义重复
   - 新增代码与既有函数、服务、hook、validator、mapper、policy、schema 做了同一件事。
   - 名字不同但业务规则、数据转换、状态机、权限判断、错误处理语义相同或高度重叠。
   - AI 生成了“看起来局部合理”的新逻辑，但项目里已有等价抽象。

2. 跨文件重复 validation
   - 同一字段、请求、权限、状态、边界条件在 controller / service / UI / schema / test helper 中重复校验。
   - 新增 validation 与现有 source of truth 不一致，可能造成 drift。
   - 应优先指出“哪个文件应该是唯一规则来源”，而不是机械建议“抽 helper”。

3. 过度抽象
   - 为一次性需求引入 framework、manager、factory、strategy、registry、adapter、base class、generic type 等。
   - 抽象没有两个以上真实调用方，或者隐藏了比它减少的重复更多的复杂度。
   - 命名泛化但业务边界不清，未来改动会被迫理解间接层。

4. 防御性过度
   - 对内部不变量反复做 null/undefined/type/range 检查，掩盖上游契约不清。
   - catch 后吞错、fallback 默认值、optional chaining、空数组兜底让错误静默。
   - 增加“不可能发生”的分支，却没有说明来源、恢复策略或观测信号。

## 审查方法

先理解变更意图，再比较新增代码与既有代码。不要只看 diff 中的新增行；必须考虑调用路径、已有模块职责和项目约定。

每条 finding 必须满足：
- 有具体文件和位置。
- 有至少一个证据：相似逻辑位置、重复规则、现有抽象、调用链或不变量来源。
- 说明为什么这是实际维护风险，而不是风格偏好。
- 给出最小修复方向。
- 标注置信度：High / Medium / Low。
- 如果证据不足，降级为“需要确认”，不要写成确定问题。

## 不要做

- 不报告格式、命名、import 顺序、lint、简单性能微优化。
- 不泛泛建议“提高可读性”“增加注释”“抽象成公共函数”。
- 不因为代码长就说它需要拆分；必须指出具体重复语义或职责泄漏。
- 不建议大重构，除非当前变更已经引入明确设计债。
- 不输出超过 5 条 finding。没有高价值问题时，明确说“未发现值得阻塞的语义级问题”。

## 严重程度

- Blocker：会导致业务规则分叉、权限/validation 不一致、错误被静默吞掉，或明显破坏既有架构边界。
- High：短期可工作，但会让后续改动很容易改漏、重复修复或产生行为漂移。
- Medium：设计上偏重或重复，但影响范围有限。
- Low：只作为可选提醒，不应阻塞合并。

## 输出要求

用中文输出。先给决策摘要，再列 findings。每条 finding 控制在 120 字以内，必要时附一行“建议”。最后给一个 3 项以内的验证清单。
```

## 4. Output 格式建议：5 分钟内读完并决定

建议输出永远固定为四块：**结论、阻塞项、高信号建议、验证清单**。最多 5 条 finding。

```markdown
## Review 结论

建议：Request changes / Approve with comments / Approve

风险摘要：本次变更主要风险是 <一句话>。
发现数量：Blocker 1，High 2，Medium 1。

## 必须处理

### 1. [Blocker] validation 规则在 API 与 service 分叉
位置：`src/api/user.ts:42`，`src/domain/userPolicy.ts:18`
问题：新增 email 状态校验重复了 `userPolicy.canInvite` 的部分规则，但漏掉 suspended user。
影响：后续修改邀请规则时容易只改一处，产生权限漂移。
建议：让 API 调用现有 policy，或把新增规则并入 policy。
置信度：High

## 建议处理

### 2. [High] 一次性 factory 增加了不必要间接层
位置：`src/payments/providerFactory.ts:1`
问题：当前只有 Stripe 一个调用方，factory 没有隔离变化点，反而隐藏初始化参数。
建议：先内联到调用点；等第二个 provider 出现再抽象。
置信度：Medium

## 需要确认

- `src/forms/validate.ts` 与 `src/schema/user.ts` 的 age 规则看起来重复，但我没有看到 schema 是否用于运行时校验。请确认 source of truth。

## 验证清单

- 修改后跑现有 validation / policy 单测。
- 搜索同一业务规则是否仍有第二份实现。
- 确认没有用 fallback 或 catch 吞掉应暴露的契约错误。
```

我建议产品上再加两个硬限制：

- **默认少说**：超过 5 条 finding 自动只保留 Blocker/High；nits 永不输出。
- **证据优先**：没有跨文件证据的 finding 不进入主列表，只能进“需要确认”。
- **可采纳率作为核心指标**：不要优化“发现更多问题”，优化“人类 5 分钟内能决定且愿意采纳”。

---

# 综合建议（kiro-workspace 落地路径）

## 整体观察

三层独立调研后，**有共识也有冲突**：

**共识**：
- "**先证明现有代码里没有更合适的落点，再允许新增**" 是 A 层结论核心 —— 也是 C 层 reviewer 的主要审查方向
- "**PR/新代码严格 gate，legacy 只防恶化**" 是 B 层关键策略 —— 避免 CI 一上来全 fail
- "**Cognitive complexity 优于 Cyclomatic complexity**"（SonarSource 论证）—— B 层应优先选 cognitive
- "**少而准比多而泛重要**" —— C 层结论"超过 5 条 finding 只保留 Blocker/High"

**冲突 / 取舍**：
- A 层的 prompt rules 和 C 层的 reviewer prompt 有重叠 —— 实施时要避免双重 enforce 浪费 token，**A 层是 prevent / C 层是 detect**，分工清楚

## 落地映射（→ M1.9 实施 sequence）

| Codex 产出 | 落地到 kiro 哪里 | 何时做 |
|---|---|---|
| A 层 "Code Quality Constraints for AI Codegen" 10 条 rules | `.kiro/steering/code-quality.md` 新文件，被 AI-DLC code-generation stage 加载 | M1.9 step 7.1 (9-A) |
| B 层多语言工具矩阵（xenon / jscpd / PMD CPD / ruff / radon） | (1) `tech-env.md` 模板加 "Code Quality Tooling" 段；(2) `build-and-test.md` steering override 加质量 gate | M1.9 step 7.3 (9-B) |
| B 层阈值表（cognitive A≤15 / cyclomatic ≤10 / duplication ≤3% / radon B 级） | 同上，作为 gate 阈值 | M1.9 step 7.3 |
| C 层 reviewer agent 中文 prompt | `.kiro/agents/code-quality-reviewer.json` + `.kiro/prompts/code-quality-reviewer.md` | M1.9 step 7.2 (9-C) |
| C 层 output 格式（Review 结论 / 必须处理 / 建议处理 / 需要确认 / 验证清单）| 同上 prompt 内嵌 | M1.9 step 7.2 |
| C 层硬限制（≤5 finding、证据优先、可采纳率指标）| 写进 reviewer prompt 的"输出要求"段 | M1.9 step 7.2 |

## 仍需 user 决定

1. **B 层 gate 严格度**：codex 建议 "PR strict, legacy lenient"。kiro template 默认值给多严？默认建议从 cognitive ≤15 起步，半年后看实际数据再收紧
2. **C 层 reviewer 触发位置**：放在 per-unit code generation step 7 之后强制？还是放在 phase 完成 approval 之前？我建议前者（每 unit 一次，反馈快）
3. **是否引入"可采纳率" KPI**：C 层结论强调要优化"人类愿意采纳的比例"而非"找到的问题数"。要在 audit.md 里加这个指标吗？

## 实施前 sanity check

实施 M1.9 之前，建议把这份报告**先 review 一遍**：
- 三层 prompt rules 之间有没有矛盾？
- 阈值是否适合 sharp 公司项目（Python / TypeScript 混合栈）？
- reviewer 中文 prompt 措辞是否符合本地团队习惯？

review 完了再开 `feat/m1-9-quality-gate` branch 开干。

---

**报告完。** 三层 codex 原始产出 + 综合建议都在本文件中。M1.9 实施时按上面的"落地映射"表执行即可。
