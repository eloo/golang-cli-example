package main

import (
	"fmt"
	"github.com/eloo/golang-cli-example/cmd"
	"os"
)

var Version string

func main() {
	cmd.Version = Version
	if err := cmd.RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
