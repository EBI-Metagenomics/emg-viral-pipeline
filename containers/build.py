#!/usr/bin/env python

import sys
import glob
from pathlib import Path

from dockerfile_parse import DockerfileParser
import docker


def main():
    """Build the repo containers using Docker."""
    client = docker.from_env()

    for df_location in glob.glob("*/Dockerfile"):
        df_path = Path(df_location)

        df_parsed = DockerfileParser(path=df_location)

        print("")
        print("--- Building ---")
        print(f"## dockerfile {df_location}")

        tool = df_parsed.labels.get("software").lower().strip()
        version_tag = df_parsed.labels.get("software.version").lower().strip()

        print(f"## tool:{tool} - version:{version_tag}")

        try:
            image, build_log = client.images.build(
                path=str(df_path.parent),
                rm=True,
                tag=f"quay.io/microbiome-informatics/{tool}:{version_tag}",
            )
            for line in build_log:
                print(line.get("stream", "----"), end="")

            client.images.push(
                f"quay.io/microbiome-informatics/{tool}",
                tag=f"quay.io/microbiome-informatics/{tool}:{version_tag}",
            )

        except docker.errors.BuildError as build_ex:
            print(
                f"Build of {tool} with tag:{version_tag} FAILED. Exception {build_ex}",
                file=sys.stderr,
            )
            print(f"Build exception {build_ex}", file=sys.stderr)
            raise build_ex


if __name__ == "__main__":
    main()
