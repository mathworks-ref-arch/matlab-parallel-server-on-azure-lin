# Copyright 2024-2026 The MathWorks, Inc.

from setuptools import setup

setup(
    name="mwplatforminterfaces",
    version="0.0.2",
    install_requires=[
        # Common dependencies
        "requests",
        "psutil",
    ],
    extras_require={
        "aws": ["boto3"],
        "azure": ["azure-identity", "azure-mgmt-compute", "azure-mgmt-resource", "azure-mgmt-network"],
    },
)