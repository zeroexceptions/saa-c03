# Bump this and re-run `terraform apply` to simulate "someone overwrote the
# object" - that's the whole demo. Everything you need to observe the
# difference between versioned and unversioned behavior hinges on this one
# value changing between applies.
variable "object_content" {
  description = "Content written to the demo object on each apply."
  type        = string
  default     = "version 1 - hello.txt"
}
