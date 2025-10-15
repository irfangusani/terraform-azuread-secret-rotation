# terraform-azuread-secret-rotation

Production-grade pattern for automated Azure AD client secret rotation using Terraform. Copy, customize, deploy. See the accompanying blog post here: [Terraform Can Rotate Azure AD Secrets For You (If You Ask It Nicely)](link-when-published)

> [!IMPORTANT]
> This pattern involves automatic deletion and recreation of Azure AD client secrets. Test thoroughly in non-production environments first. The author is not responsible for service disruptions, deleted secrets, authentication failures, or any other issues that may result from using this pattern. Always maintain backup authentication methods and ensure you understand the rotation behavior before deploying to production.

## 📋 Requirements

- Terraform >= 1.0
- Azure AD Provider ~> 2.0
- Time Provider ~> 0.9

## ✨ The Pattern

This pattern automates secret rotation with a configurable grace period:

```text
# Using pattern's default values
Day 0          Day 365                    Day 730
 │              │                           │
 │         [Rotation Window Opens]    [Secret Expires]
 │              │<------ 365 days -------->│
 │<------------ 730 days ------------------>│
```

> [!TIP]
> Terraform must be executed during the rotation window to perform rotation. This pattern assumes regular Terraform runs (e.g., via CI/CD pipelines).

## 🎨 Pattern Variations

### Default Maximum Value (2-year rotation)

```hcl
variable "rotation_days" {
  default = 730  # 2 years
}

variable "rotation_window_days" {
  default = 365  # 1 year window
}
```

### Short-lived Development (90-day rotation)

```hcl
variable "rotation_days" {
  default = 90   # 3 months
}

variable "rotation_window_days" {
  default = 30   # 1 month window
}
```

## ✅ When to Use This Pattern

This approach is ideal when:

- ✅ You run Terraform regularly enough for the secret to be rotated within the `rotation_window_days` (e.g. once a year) and/or
- ✅ Brief downtime during rotation is acceptable (e.g. you forgot to run Terraform within that year)
- ✅ You're managing multiple app registrations (this can easily scale)
- ✅ You prefer simplicity over sophistication (or rather, you don't necessarily NEED sophistication)

## ❌ When to Consider Alternatives

Choose a different approach if:

- ❌ **Zero downtime required** → Use a method involving multiple secrets that can be rotated independently

## 📖 How It Works

The pattern uses three resources that work together:

**1. Expiry Timer** (`time_rotating.token_expiry`)

```hcl
resource "time_rotating" "token_expiry" {
  rotation_days = 730  # When secret expires
}
```

**2. Rotation Window Timer** (`time_rotating.refresh_window`)

```hcl
resource "time_rotating" "refresh_window" {
  rotation_days = 365  # When rotation window opens
}
```

**3. Application Password with Rotation Trigger**

```hcl
resource "azuread_application_password" "this" {
  start_date = time_rotating.token_expiry.rfc3339
  end_date   = time_rotating.token_expiry.rotation_rfc3339
  
  # This is the magic - rotates when refresh_window changes
  rotate_when_changed = {
    time_rotation = time_rotating.refresh_window.rfc3339
  }
}
```

**The logic:**

- Expiry timer = 730 days (2 years)
- Window opens = 365 days (1 year before expiry)
- Refresh window = 730 - 365 = 365 days

When day 365 hits, `time_rotating.refresh_window` rotates, which triggers `rotate_when_changed`, which generates a new secret.

## 🤝 Contributing

**Found a better approach?** Share it!

**Discovered a gotcha?** Document it!

**Built a variation?** Contribute it!

### How to Contribute

1. **Share experiences** - Open an issue describing your use case
2. **Submit variations** - PRs welcome for new pattern variations
3. **Improve docs** - Found something unclear? Help make it better
4. **Report bugs** - Something broken? Let us know

### Pattern Variations We'd Love to See

- [ ] Integration with specific Azure services (App Service, Functions, AKS)
- [ ] Monitoring/alerting configurations
- [ ] Zero-downtime dual-secret pattern (for comparison)
- [ ] Migration guides from manual rotation
- [ ] CI/CD platform examples (GitHub Actions, Azure DevOps, GitLab)

## 📖 Related Resources

- **Blog Post:** [Terraform Can Rotate Azure AD Secrets For You (If You Ask It Nicely)](link-when-published) - Deep dive into the pattern
- **Terraform Docs:** [time_rotating resource](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating)
- **Azure AD Provider:** [azuread_application_password](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password)

## 🙏 Acknowledgments

- Inspired by the Azure Terraformer community
- Pattern refined through real-world use in https://github.com/codycodes/terraform-azuread-ms365-hass

---

**Questions?** Open an issue or discussion.

**Want to share your experience?** We'd love to hear it!

**Found this useful?** Star the repo 🌟 and share it with your team.