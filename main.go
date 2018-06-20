package main

import (
	"fmt"
	"os"

	"github.com/eloo/golang-cli-example/cmd"
)

// SemVer is the semantic version of this build
var SemVer string

// GitCommit is the git commit sha of this build
var GitCommit string

func main() {
	cmd.SemVer = SemVer
	cmd.GitCommit = GitCommit
	if err := cmd.RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
