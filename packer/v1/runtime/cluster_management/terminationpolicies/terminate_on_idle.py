#!/usr/bin/env python3

# Copyright 2024 The MathWorks, Inc.

from mwplatforminterfaces import CloudInterface

from cluster_management_interface import ClusterManagementProgramInterface
from constants import (
    STATUS_SUCCESS,
    STATUS_CLUSTER_ISSUE,
    WAS_MJS_BUSY,
    MJS_STATUS_LOG_FILE,
    CLUSTER_READY_FOR_TERMINATION,
    CLUSTER_AUTO_TERMINATED,
)

import os
from datetime import datetime, timezone

UNUSED_CLUSTER_TIMEOUT_SECONDS = 1800


def main(
    cloud_interface: CloudInterface,
    cluster_management_interface: ClusterManagementProgramInterface,
) -> int:
    """Execute terminate on idle routine.

    The routine checks the last line of the mjs_status_transitions.log file. If it says that MJS is idle, calculate the time delta
    between now and the timestamp in the last line. If the time delta is greater than the idle timeout, then terminate
    the cluster i.e. delete all the nodes in the cluster and then deallocate the head-node.

    Args:
        cloud_interface (CloudInterface): Cloud provider specific
        implementation of AbstractCloudInterface.
        cluster_management_interface (ClusterManagementProgramInterface): Class to read and update
        dictionary containing state and config of the cluster management program.

    Returns:
        status (int): Status code of program.
                        0: Successful
                        1: Faced an issue with cloud provider
                        2: Faced an issue with cluster
                        3: Faced an issue with both
    """
    mjs_status_log_path = cluster_management_interface.cluster_management_config[
        MJS_STATUS_LOG_FILE
    ]

    # If MJS was never busy, then we set the idle timeout to at least UNUSED_CLUSTER_TIMEOUT_SECONDS
    # This is done to ensure that the user gets enough time to submit their first job before termination begins.
    idle_timeout_seconds = cloud_interface.get_idle_timeout_seconds()
    if not cluster_management_interface.cluster_management_state[WAS_MJS_BUSY]:
        idle_timeout_seconds = max(idle_timeout_seconds, UNUSED_CLUSTER_TIMEOUT_SECONDS)

    if os.path.isfile(mjs_status_log_path):
        with open(mjs_status_log_path, "r") as file:
            lines = file.readlines()
            if lines:
                last_line = lines[-1]
                if "MJS idle since" in last_line:
                    # Extract the timestamp from the last line
                    timestamp_str = last_line.split("since: ")[1].split(" UTC")[0]
                    timestamp = (
                        datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S")
                    ).replace(tzinfo=timezone.utc)
                    current_time = datetime.now(timezone.utc)
                    time_delta = int((current_time - timestamp).total_seconds())
                    print(
                        f"> MJS has been idle for {time_delta} seconds. Total timeout is {idle_timeout_seconds} seconds."
                    )
                    if time_delta > idle_timeout_seconds:
                        print(
                            "> MJS has been idle for more than the timeout. Marking cluster as ready for termination in the cluster management data file."
                        )
                        cluster_management_interface.update_state(
                            {
                                CLUSTER_READY_FOR_TERMINATION: True,
                                CLUSTER_AUTO_TERMINATED: True,
                            }
                        )
                    else:
                        print(
                            "> MJS has been idle for less than the timeout. Skipping cluster termination."
                        )
                else:
                    print("> MJS is busy. Skipping cluster termination.")
    else:
        print(
            f"~ Failed to find file {mjs_status_log_path}. Skipping cluster termination as MJS state is not known."
        )
        return STATUS_CLUSTER_ISSUE

    return STATUS_SUCCESS
