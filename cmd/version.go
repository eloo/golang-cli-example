package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// SemVer is the semantic version of this build
var SemVer string

// GitCommit is the git commit sha of this build
var GitCommit string

func init() {
	RootCmd.AddCommand(versionCmd)
}

var versionCmd = &cobra.Command{
	Use:     "version",
	Aliases: []string{"v"},
	Short:   "Print the version",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("golang-cli-example {SemVer: \"%s\", GitCommit: \"%s\"}\n", SemVer, GitCommit)
	},
}
