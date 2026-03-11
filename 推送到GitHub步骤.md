# 推送代码到 GitHub 步骤

代码已经完成 Git 初始化和首次提交，按以下步骤即可同步到 GitHub：

---

## 第一步：在 GitHub 创建新仓库

1. 打开 https://github.com/new
2. **Repository name**：建议填 `QianqianDiary` 或 `qianqian-diary`
3. **Description**（可选）：`小狗钱钱 - iOS 日记 App + Flask 后端`
4. 选择 **Public**
5. 不要勾选 "Add a README" / "Add .gitignore"（本地已有）
6. 点击 **Create repository**

创建后，会看到仓库地址，类似：`https://github.com/你的用户名/QianqianDiary.git`

---

## 第二步：添加远程并推送

在终端执行（把 `你的用户名` 和 `QianqianDiary` 换成你的实际值）：

```bash
cd "/Users/houyuexian/Downloads/小狗钱钱app开发/code"

# 添加 GitHub 远程仓库
git remote add origin https://github.com/你的用户名/QianqianDiary.git

# 推送到 main 分支
git push -u origin main
```

如果提示输入账号密码，请使用 **Personal Access Token** 而非密码（GitHub 已不再支持密码推送）。

---

## 已提交内容

- ✅ iOS 项目（QianqianDiary、Sources/Services）
- ✅ Flask 后端（backend/）
- ✅ Docker 配置
- ✅ 各类文档

已忽略：`.env`、`__pycache__`、`venv` 等，不会提交到 GitHub。
