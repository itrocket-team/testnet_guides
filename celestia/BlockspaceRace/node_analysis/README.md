# <img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4" style="border-radius: 50%; vertical-align: middle;" width="35" height="35" /> Celestia Consensus Full Node Analysis with Different Pruning
> For Celestia Testnet — blockspacerace-0

This guide will thoroughly examine the server loading requirements for deploying FULL Node. As the Celestia evolves, it becomes essential to test the performance and efficiency of different configurations. In this article, we will delve into testing Celestia Node with three distinct pruning configurations: Custom, Nothing, and Default. We will measure the impact of these configurations on performance, disk space usage, and overall system resources.

## The [basic settings](https://github.com/itrocket-team/testnet_guides/blob/main/celestia/BlockspaceRace/full.md) for each node are the same, with the exception for pruning.
| Server      | Pruning                    | Indexer   |
|-------------|----------------------------|-----------|
| Server 1    | custom 100/0/10            | null      |
| Server 2    | default         | null      |
| Server 3    | nothing            | null      |

## Testing Methodology

To conduct our tests, we will employ a combination of tools and commands. For measuring memory usage, we will utilize the popular tool `htop`, which provides real-time monitoring of system resources, including memory consumption. Disk space usage will be evaluated using the "du" command with the argument `du -h $HOME/.celestia-app/data` to analyze the occupied space within the Celestia Node data directory.
>We will measure the Celestia node's performance and behavior at four intervals: immediately after synchronization, 2 hours, 4 hours, and 6 hours. These measurements will provide valuable insights into how the node works over time. All nodes catching up height from the 0 block, without using Snapshot ot Statesync servoces

| Parameter     | Server 1                    | Server 2   | Server 3
|-------------|----------------------------|-----------|-----------|
| Pruning    | custom 100/0/10            | default     | nothing  |
| RAM usage at synch   |   1.8 GB      |  4.8 GB     |  3.9 GB     |
| RAM usage at height: 486695    |  1.7 GB       |  4.5 GB     |    3.6 GB   |
| Disk usage at height: 486695   |  21 GB       |  99 GB     |  112 GB     |
| RAM usage at height: 490095   |    2.0 GB     |   3.7 GB    |   3.4 GB    |
| Disk usage at height: 490095     | 22 GB        | 100 GB      |   114 GB    |
| RAM usage at height: 494550   |    2 GB     |  4.1  GB    |  3.6  GB    |
| Disk usage at height: 494550     |  22 GB        |  101GB      |    116 GB    |
1. **Analisis at height 486696**
>`VIRT`, `RES`, and `SHR` are measurements that provide insight into the memory consumption of a process.
'VIRT' refers to the total virtual memory used by the process, including all code, data, and shared libraries, pages that have been swapped out and pages that have been mapped but not used.
- Server 1
<img src="https://github.com/itrocket-team/testnet_guides/blob/main/utils/basket/1_S1.jpg" style="width: 100%; fill: white" />

 - Server 2
 
<img src="https://github.com/itrocket-team/testnet_guides/blob/main/utils/basket/1s2.jpg" style="width: 100%; fill: white" />

- Server 3

<img src="https://github.com/itrocket-team/testnet_guides/blob/main/utils/basket/1s3.jpg" style="width: 100%; fill: white" />

In the context of using the system monitoring tool 'htop', 'VIRT', 'RES', and 'SHR' are indicators that display a process's memory usage.

'VIRT' (short for Virtual) represents the total virtual memory used by the process. This includes all code, data, shared libraries, as well as pages that have been swapped out and pages that have been mapped but not used.

'RES' (short for Resident) signifies the amount of physical memory that the process has used which hasn't been swapped to disk. However, 'RES' includes not just the memory used exclusively by this process but also memory that is shared with other processes.

'SHR' (short for Shared) is the amount of memory that the process shares with other processes.

If you want to determine the amount of memory that is exclusively used by a specific process, you could subtract 'SHR' from 'RES'. This will give an approximate amount of memory that is exclusively used by this process and not shared with other processes.  
  
In our case, at hight 486695:
- `Server-1` RAM usage ~ 3535-1796=1739 MB, Disk space usage ~ 21 GB
- `Server-2` RAM usage ~ 9830-5182=4648 MB, Disk space usage ~ 99 GB
- `Server-3` RAM usage ~ 7475-3820=3655 MB, Disk space usage ~ 112 GB

After 10 hours, at hight 490095:
- `Server-1` RAM usage ~ 3805-1726=2079 MB, Disk space usage ~ 22 GB
- `Server-2` RAM usage ~ 9830-6009=3821 MB, Disk space usage ~ 100 GB
- `Server-3` RAM usage ~ 7809-4299=3510 MB, Disk space usage ~ 114 GB

After 20 hours, at hight 490095:
- `Server-1` RAM usage ~ 3888-1771=2037 MB, Disk space usage ~ 22 GB
- `Server-2` RAM usage ~ 9830-5630=4200 MB, Disk space usage ~ 101 GB
- `Server-3` RAM usage ~ 8535-4849=3686 MB, Disk space usage ~ 116 GB

## Performance and Resource Utilization
- Server 1 (Pruning: custom 100/0/10): This server displayed the most efficient use of resources. The RAM usage was the lowest among the three servers, and the disk space usage was also significantly lower. This suggests that a custom pruning configuration could provide the best trade-off between performance and resource utilization.

- Server 2 (Pruning: default): The default pruning setting resulted in significantly higher RAM and disk usage compared to the custom setting on Server 1. This suggests that the default configuration may be less efficient in terms of resource utilization.

- Server 3 (Pruning: nothing): This server had the highest disk usage among all three servers. The RAM usage was slightly lower than Server 2 but higher than Server 1. This indicates that not pruning at all can lead to substantial disk usage since in this case, all data is saved.

## Conclusions

The adoption of custom pruning settings can notably enhance resource efficiency, resulting in substantial savings in both operational memory and disk space. This finding underscores the importance of tailored configurations in optimizing system performance and resource utilization.
Absolutely, our exploration and analysis will not cease here. We are looking forward to further investigating and evaluating the performance of both bridge and validator nodes in the future. These studies will enhance our understanding and provide invaluable insights, ultimately contributing to the optimization and improvement of the system.

Thank you for your attention and interest. Stay tuned for our forthcoming analysis and findings!
<img src="https://itrocket.net/logo.svg" style="width: 100%; fill: white" />


