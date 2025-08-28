# Commit Message Guide - NutriPlan Project

## 🎯 Purpose

This guide ensures all commit messages are professional, meaningful, and accurately describe the changes made to the codebase. Consistent commit messages help maintain project organization and make the development history clear and traceable.

## 📝 Commit Message Format

### **Conventional Commit Structure**
```
type(scope): brief description

[optional body]

[optional footer]
```

### **Components Breakdown**

#### **1. Type (Required)**
- **feat**: New feature or enhancement
- **fix**: Bug fix or issue resolution
- **docs**: Documentation updates
- **style**: Code formatting, missing semicolons, etc.
- **refactor**: Code refactoring without changing functionality
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates, etc.
- **perf**: Performance improvements
- **ci**: CI/CD configuration changes
- **build**: Build system or external dependency changes

#### **2. Scope (Optional)**
- **ui**: User interface changes
- **api**: API-related changes
- **db**: Database schema or query changes
- **auth**: Authentication and authorization
- **nutrition**: Nutrition calculation features
- **meal**: Meal tracking and planning
- **recipe**: Recipe management features
- **service**: Service layer changes
- **model**: Data model changes

#### **3. Description (Required)**
- Clear, concise description of the change
- Use imperative mood ("add" not "added")
- Keep under 72 characters
- Start with lowercase letter

## ✅ Good Examples

### **Feature Additions**
```
feat(nutrition): implement FNRI nutrition calculation service
feat(ui): add scroll-based navigation transparency
feat(meal): implement AI-powered meal suggestions
feat(recipe): add user feedback and rating system
```

### **Bug Fixes**
```
fix(nutrition): resolve inaccurate protein calculation for Lumpia Shanghai
fix(ui): correct profile screen spacing issues
fix(api): handle missing nutrition data gracefully
fix(db): resolve SQL syntax error in recipe updates
```

### **Documentation**
```
docs(readme): add comprehensive project setup instructions
docs(api): update nutrition service documentation
docs(structure): add project organization guidelines
docs(commit): create commit message standards guide
```

### **Code Improvements**
```
refactor(nutrition): optimize ingredient quantity estimation
refactor(ui): simplify meal planner screen logic
refactor(service): improve error handling in FNRI service
refactor(model): standardize nutrition data structure
```

### **Performance & Testing**
```
perf(nutrition): implement local CSV caching for faster calculations
test(nutrition): add comprehensive FNRI service tests
test(ui): add widget tests for recipe screens
perf(ui): optimize image loading and caching
```

## ❌ Bad Examples

### **Vague Descriptions**
```
fix: stuff
update: things
change: something
fix bug
```

### **Unprofessional Language**
```
fix: stupid bug that was annoying
update: crap that was broken
fix: everything that was wrong
```

### **Incomplete Information**
```
fix
update
change
```

### **Too Long Descriptions**
```
fix(nutrition): resolve the complex issue where the nutrition calculation was producing unrealistic values like 80+ grams of protein for simple dishes like Lumpia Shanghai which was caused by corrupted FNRI data and poor ingredient matching
```

## 🔧 Implementation Guidelines

### **1. Before Committing**
- Review your changes thoroughly
- Ensure the commit represents a single logical change
- Test that your changes work as expected
- Consider if the change needs to be split into multiple commits

### **2. Writing the Message**
- Start with the type and scope
- Write a clear, action-oriented description
- Use present tense and imperative mood
- Keep it concise but descriptive

### **3. Commit Body (When Needed)**
- Use for complex changes that need explanation
- Explain the "why" not the "what"
- Reference related issues or discussions
- Separate paragraphs with blank lines

### **4. Commit Footer (When Needed)**
- Reference related issues: `Closes #123`
- Breaking changes: `BREAKING CHANGE: description`
- Co-authored commits: `Co-authored-by: Name <email>`

## 📋 Commit Message Templates

### **New Feature**
```
feat(scope): add [feature name]

- Implement [specific functionality]
- Add [new components/services]
- Update [related files]

Closes #[issue-number]
```

### **Bug Fix**
```
fix(scope): resolve [issue description]

- Fix [specific problem]
- Update [affected components]
- Add [error handling if applicable]

Fixes #[issue-number]
```

### **Documentation Update**
```
docs(scope): update [documentation area]

- Add [new information]
- Clarify [existing content]
- Update [examples or instructions]
```

### **Code Refactoring**
```
refactor(scope): improve [component/functionality]

- Restructure [specific code]
- Optimize [performance aspects]
- Simplify [complex logic]
```

## 🎨 Special Cases

### **Breaking Changes**
```
feat(api)!: change nutrition calculation response format

BREAKING CHANGE: The nutrition calculation API now returns
nutrition data in a different structure. Update your client
code to handle the new format.

Migration guide: [link to migration docs]
```

### **Revert Commits**
```
revert: feat(nutrition): implement FNRI nutrition calculation service

This reverts commit [commit-hash] due to [reason].
```

### **Merge Commits**
```
merge: integrate feature branch 'ai-meal-suggestions'

- Merge AI meal suggestion system
- Resolve conflicts in nutrition service
- Update documentation
```

## 🔍 Review Process

### **Self-Review Checklist**
- [ ] Does the commit message clearly describe the change?
- [ ] Is the scope appropriate for the change?
- [ ] Does the type accurately categorize the change?
- [ ] Is the description concise and clear?
- [ ] Are there any spelling or grammar errors?

### **Team Review Guidelines**
- Review commit messages during code reviews
- Suggest improvements for unclear messages
- Ensure consistency across team members
- Use commit message quality as part of code review criteria

## 📚 Examples by Category

### **UI/UX Changes**
```
feat(ui): implement dynamic navigation transparency
style(ui): standardize button styling across screens
fix(ui): resolve profile screen layout spacing issues
refactor(ui): simplify meal planner screen structure
```

### **Backend Services**
```
feat(service): add FNRI nutrition calculation service
fix(service): handle missing ingredient data gracefully
refactor(service): optimize nutrition calculation algorithm
test(service): add comprehensive service layer tests
```

### **Database Changes**
```
feat(db): add sodium and cholesterol fields to nutrition tracking
fix(db): resolve SQL syntax error in recipe updates
refactor(db): optimize meal history queries
docs(db): update database schema documentation
```

### **Performance Improvements**
```
perf(nutrition): implement local CSV caching for faster calculations
perf(ui): optimize image loading with lazy loading
perf(api): reduce database query response time
perf(service): implement connection pooling for database
```

## 🚀 Best Practices Summary

1. **Be Specific**: Clearly describe what changed and why
2. **Use Consistent Format**: Follow the conventional commit structure
3. **Keep It Professional**: Avoid casual or unprofessional language
4. **Reference Issues**: Link commits to related issues when applicable
5. **Review Before Committing**: Ensure message quality and accuracy
6. **Split Large Changes**: Break complex changes into logical commits
7. **Use Imperative Mood**: Write as if giving commands ("add" not "added")
8. **Be Concise**: Keep descriptions under 72 characters when possible

---

Following these guidelines ensures your commit messages are professional, meaningful, and contribute to a well-organized and maintainable codebase. Remember: good commit messages are an investment in your project's future maintainability.
