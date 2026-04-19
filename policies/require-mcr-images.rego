# Rego policy: block Dockerfiles that use base images outside mcr.microsoft.com
package containerization.require_mcr

# Extract all FROM lines from the Dockerfile
from_lines := [line |
  line := split(input.content, "\n")[_]
  startswith(trim_space(line), "FROM ")
]

# Flag each FROM line that does not reference mcr.microsoft.com
violations contains result if {
  some line in from_lines
  not contains(line, "mcr.microsoft.com/")

  result := {
    "rule": "require-mcr-images",
    "category": "security",
    "priority": 95,
    "severity": "block",
    "message": sprintf("Base image must come from mcr.microsoft.com: %s", [trim_space(line)]),
  }
}

default allow := false
allow if count(violations) == 0
result := { "allow": allow, "violations": violations }
