## Experiment formulation

To evaluate the performance of our heuristics, we run four experimental scenarios. In the first and second scenarios, we fixed each node threshold to a random value between $1$ and its degree. In the other two scenarios, each node threshold varies proportionally - from $0.2$ to $0.8$ - to the degree of the node. Concerning the hyperedge thresholds, we fixed each edge threshold to a random value between $1$ and its degree in the first and third scenarios. In the remaining settings, we set each hyperedge activation threshold proportional to its degree scaled of factor $0.5$ (majority policy).

We simulated the execution of each heuristic followed by the **optimization procedure** $50$ times per experiment. 

The following table summarizes the threshold settings in the four experimental scenarios.

<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;}
.tg td{border-color:grey;border-style:solid;border-width:1px;font-size:15px;
  overflow:hidden;padding:10px 5px;word-break:normal;}
.tg th{border-color:grey;border-style:solid;border-width:1px;font-size:14px;
  font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
.tg .tg-c3ow{border-color:inherit;text-align:center;vertical-align:top}
.tg .tg-0pky{border-color:inherit;text-align:left;vertical-align:top}
.tg .tg-7btt{border-color:inherit;font-weight:bold;text-align:center;vertical-align:top}
</style>
<table class="tg">
<thead>
  <tr>
    <th class="tg-0pky"></th>
    <th class="tg-7btt" colspan="2">Node thresholds</th>
    <th class="tg-7btt" colspan="2">Hyperedge thresholds</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-c3ow"></td>
    <td class="tg-c3ow"><span style="font-weight:bold">Random</span></td>
    <td class="tg-c3ow"><span style="font-weight:bold">Proportional</span></td>
    <td class="tg-c3ow"><span style="font-weight:bold">Random</span></td>
    <td class="tg-c3ow"><span style="font-weight:bold">Majority Policy</span></td>
  </tr>
  <tr>
    <td class="tg-0pky"><span style="font-weight:bold">Scenario 1</span> -<span style="font-weight:bold"> </span><span style="font-style:italic">randV_randE.jl</span></td>
    <td class="tg-c3ow">*</td>
    <td class="tg-c3ow"></td>
    <td class="tg-c3ow">*</td>
    <td class="tg-c3ow"></td>
  </tr>
  <tr>
    <td class="tg-0pky"><span style="font-weight:bold">Scenario 2</span><span style="font-weight:normal"> - </span><span style="font-style:italic">randV_propE05.jl</span></td>
    <td class="tg-c3ow">*</td>
    <td class="tg-c3ow"></td>
    <td class="tg-c3ow"></td>
    <td class="tg-c3ow">*</td>
  </tr>
  <tr>
    <td class="tg-0pky"><span style="font-weight:bold">Scenario 3 </span><span style="font-weight:normal">- </span><span style="font-style:italic">propV_randE.jl</span></td>
    <td class="tg-c3ow"></td>
    <td class="tg-c3ow">*</td>
    <td class="tg-c3ow">*</td>
    <td class="tg-c3ow"></td>
  </tr>
  <tr>
    <td class="tg-0pky"><span style="font-weight:bold">Scenario 4 </span><span style="font-weight:normal">- </span><span style="font-style:italic">propV_propE05.jl</span></td>
    <td class="tg-c3ow"></td>
    <td class="tg-c3ow">*</td>
    <td class="tg-c3ow"></td>
    <td class="tg-c3ow">*</td>
  </tr>
</tbody>
</table>