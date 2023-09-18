# Polybenchmark

Baseline Results

julia tuning.jl --polybench-source datamining/correlation/correlation.c --read-environment openmp_env.txt --read-counters counters.list --measurement counters

-O3 optimization flag enabled.

More L2 data cache misses than accesses. It has to do with prefetching and/or the load store queue.

```
correlation PAPI_TOT_CYC:        22553130255 / 22840207849 / 2.27230897454e10
correlation PAPI_TOT_INS:        7090069367 / 7090069421 / 7.0900694005e9
correlation PAPI_L1_DCM:         2241358430 / 2245903711 / 2.2424036717e9
correlation PAPI_L2_DCM:         3400226981 / 4027217964 / 3.8793666109e9
correlation PAPI_LST_INS:        3032960484 / 3035207537 / 3.0340789365e9
correlation PAPI_RES_STL:        19328245656 / 19655837195 / 1.95306215156e10
correlation PAPI_VEC_SP:         0 / 0 / 0.0
correlation PAPI_VEC_DP:         2023563600 / 2023563600 / 2.0235636e9
```

```
Instructions Per Cycle: 0.31437185378859506
Vector Instructions Per Cycle: 0.089724290026276
L1 Data Cache Miss Rate: 0.7390002084840879
L2 Data Cache Miss Rate: 1.121091751421579
L1 Accesses Per Instruction: 0.427775854791577
L1 Accesses Per Vector Instruction: 1.4988214277030878
Percentage Of Cycles Stalled: 0.8570094455830561
```

# Loop transformations

### Loop Fission

First, I am transforming all fused rectangular loop nests into "perfect loops" for maximum distribution. I am not changing the triangular loop.

```
correlation PAPI_TOT_CYC:        22431781577 / 22886465054 / 2.26703500077e10
correlation PAPI_TOT_INS:        7090073797 / 7090074466 / 7.0900741913e9
correlation PAPI_L1_DCM:         2240136172 / 2243937859 / 2.2418492316e9
correlation PAPI_L2_DCM:         3608205102 / 3979404665 / 3.8785039941e9
correlation PAPI_LST_INS:        3032854790 / 3036354063 / 3.0354758269e9
correlation PAPI_RES_STL:        19224545680 / 20084267373 / 1.95481321575e10
correlation PAPI_VEC_SP:         0 / 0 / 0.0
correlation PAPI_VEC_DP:         2023563000 / 2023563000 / 2.023563e9
```

```
Instructions Per Cycle: 0.31607270125479786
Vector Instructions Per Cycle: 0.09020964264714586
L1 Data Cache Miss Rate: 0.7386229566236503
L2 Data Cache Miss Rate: 1.1897058553205575
L1 Accesses Per Instruction: 0.42776068018971564
L1 Accesses Per Vector Instruction: 1.498769640480677
Percentage Of Cycles Stalled: 0.857022685158076
```

The results are essentially the same as the unmodified version.

### Loop permutations

Here we permute the inner loops one by one.

```
  for (j = 0; j < _PB_M; j++)
    mean[j] = 0;

  // Permuted
  for (i = 0; i < _PB_N; i++)
    for (j = 0; j < _PB_M; j++)
      mean[j] += data[i][j];

  for (j = 0; j < _PB_M; j++)
    mean[j] /= float_n;
```

```
correlation PAPI_TOT_CYC:        22519750227 / 22799267282 / 2.26852857468e10
correlation PAPI_TOT_INS:        7087578365 / 7087578420 / 7.0875783997e9
correlation PAPI_L1_DCM:         2238634227 / 2240946928 / 2.2394482668e9
correlation PAPI_L2_DCM:         3973313606 / 4077881566 / 4.0194516951e9
correlation PAPI_LST_INS:        3032942303 / 3035440450 / 3.034345738e9
correlation PAPI_RES_STL:        19357562147 / 19564447519 / 1.94701470735e10
correlation PAPI_VEC_SP:         0 / 0 / 0.0
correlation PAPI_VEC_DP:         2022723000 / 2022723000 / 2.022723e9
```

```
Instructions Per Cycle: 0.3147272191546052
Vector Instructions Per Cycle: 0.0898199571314455
L1 Data Cache Miss Rate: 0.7381064337378528
L2 Data Cache Miss Rate: 1.3100524866793024
L1 Accesses Per Instruction: 0.427923635804484
L1 Accesses Per Vector Instruction: 1.4994353171442654
Percentage Of Cycles Stalled: 0.8595815651539198
```

This change is negligible.

Now we try the next loop nest.

```
  for (j = 0; j < _PB_M; j++)
    stddev[j] = SCALAR_VAL(0.0);

  // Permuted
  for (i = 0; i < _PB_N; i++)
    for (j = 0; j < _PB_M; j++)
      stddev[j] += (data[i][j] - mean[j]) * (data[i][j] - mean[j]);

  for (j = 0; j < _PB_M; j++)
  {
    stddev[j] /= float_n;
    stddev[j] = SQRT_FUN(stddev[j]);
    stddev[j] = stddev[j] <= eps ? SCALAR_VAL(1.0) : stddev[j];
  }
```

```
correlation PAPI_TOT_CYC:        22437098163 / 22752018443 / 2.25927198516e10
correlation PAPI_TOT_INS:        7082571760 / 7082572403 / 7.0825719751e9
correlation PAPI_L1_DCM:         2237076803 / 2240277706 / 2.2379845354e9
correlation PAPI_L2_DCM:         3947053667 / 4057733794 / 4.0041083348e9
correlation PAPI_LST_INS:        3031032935 / 3033849130 / 3.0332249805e9
correlation PAPI_RES_STL:        19255193433 / 19533134001 / 1.94121433764e10
correlation PAPI_VEC_SP:         0 / 0 / 0.0
correlation PAPI_VEC_DP:         2020203000 / 2020203000 / 2.020203e9
```

```
Instructions Per Cycle: 0.315663447587868
Vector Instructions Per Cycle: 0.09003851502202834
L1 Data Cache Miss Rate: 0.7380575701332655
L2 Data Cache Miss Rate: 1.3022140477005408
L1 Accesses Per Instruction: 0.4279565442765101
L1 Accesses Per Vector Instruction: 1.500360575150121
Percentage Of Cycles Stalled: 0.858185550248778
```

Negligible changes again.

### Strip Mining

Now I will strip mine all eligible loops.

First loop nest
```
  // Strip Mine
  for (j = 0; j < _PB_M; j += 4)
    for (jj = j; jj < min(j + 4, _PB_M); jj++)
      mean[jj] = 0;

  for (j = 0; j < _PB_M; j++)
    for (i = 0; i < _PB_N; i++)
      mean[j] += data[i][j];

  // Strip Mine
  for (j = 0; j < _PB_M; j+=4)
    for (jj = j; jj < min(j + 4, _PB_M); jj++)
      mean[jj] /= float_n;
```

Second loop nest
```
  // Strip Mine
  for (j = 0; j < _PB_M; j += 4)
    for (jj = j; jj < min(j + 4, _PB_M); jj++)
      stddev[jj] = SCALAR_VAL(0.0);

  for (j = 0; j < _PB_M; j++)
    for (i = 0; i < _PB_N; i++)
      stddev[j] += (data[i][j] - mean[j]) * (data[i][j] - mean[j]);

  // Strip Mine
  for (j = 0; j < _PB_M; j+=4)
    for (jj = j; jj < min(j + 4, _PB_M); jj++)
    {
      stddev[jj] /= float_n;
      stddev[jj] = SQRT_FUN(stddev[jj]);
      stddev[jj] = stddev[jj] <= eps ? SCALAR_VAL(1.0) : stddev[jj];
    }
```

```
correlation PAPI_TOT_CYC:        22481634985 / 22932135044 / 2.26037250721e10
correlation PAPI_TOT_INS:        7090074945 / 7090075584 / 7.0900750344e9
correlation PAPI_L1_DCM:         2239991700 / 2242834150 / 2.241057782e9
correlation PAPI_L2_DCM:         3955484519 / 4089100343 / 4.0461398478e9
correlation PAPI_LST_INS:        3034878570 / 3036365473 / 3.036053904e9
correlation PAPI_RES_STL:        19291711469 / 19554414188 / 1.9390044769e10
correlation PAPI_VEC_SP:         0 / 0 / 0.0
correlation PAPI_VEC_DP:         2023563000 / 2023563000 / 2.023563e9
```

```
Instructions Per Cycle: 0.31537185572715587
Vector Instructions Per Cycle: 0.09000960123007708
L1 Data Cache Miss Rate: 0.7380828090265239
L2 Data Cache Miss Rate: 1.3033419386529195
L1 Accesses Per Instruction: 0.4280460493778321
L1 Accesses Per Vector Instruction: 1.499769747717269
Percentage Of Cycles Stalled: 0.8581098074882741
```

### Tiling

Here I try tiling 3 of the loop nests.

```
  // Tiled
  for (j = 0; j < _PB_M; j += 2)
    for (i = 0; i < _PB_N; i += 2)
      for (jj = j; jj < j + 2; jj++)
        for (ii = i; ii < i + 2; ii++)
          mean[jj] += data[ii][jj];
```

```
  // Tiled
  for (j = 0; j < _PB_M; j += 2)
    for (i = 0; i < _PB_N; i += 2)
      for (jj = j; jj < j + 2; jj++)
        for (ii = i; ii < i + 2; ii++)
          stddev[jj] += (data[ii][jj] - mean[jj]) * (data[ii][jj] - mean[jj]);
```

```
  // Tiled
  for (j = 0; j < _PB_M; j += 2)
    for (i = 0; i < _PB_N; i += 2)
      for (jj = j; jj < j + 2; jj++)
        for (ii = i; ii < i + 2; ii++)
        {
          data[ii][jj] -= mean[jj];
          data[ii][jj] /= SQRT_FUN(float_n) * stddev[jj];
        }
```

```
correlation PAPI_TOT_CYC:        22451422625 / 22747843652 / 2.26083909942e10
correlation PAPI_TOT_INS:        7085811317 / 7085811406 / 7.0858113722e9
correlation PAPI_L1_DCM:         2240062515 / 2241911066 / 2.2410646496e9
correlation PAPI_L2_DCM:         3563421993 / 4092028142 / 3.968453461e9
correlation PAPI_LST_INS:        3040054622 / 3040568281 / 3.0404532307e9
correlation PAPI_RES_STL:        19289262515 / 19587774644 / 1.94119647349e10
correlation PAPI_VEC_SP:         0 / 0 / 0.0
correlation PAPI_VEC_DP:         2026083000 / 2026083000 / 2.026083e9
```

```
Instructions Per Cycle: 0.3156063397563877
Vector Instructions Per Cycle: 0.09024296739859708
L1 Data Cache Miss Rate: 0.7368494298718558
L2 Data Cache Miss Rate: 1.1721572261276298
L1 Accesses Per Instruction: 0.42903409165107464
L1 Accesses Per Vector Instruction: 1.5004590739866037
Percentage Of Cycles Stalled: 0.8591554681047745
```

### Loop Fusion

Next, I realize that we should have tried fusion before any of these other transformations. So I went back to the original code and just tried to fuse the first two loop nests.

```
  // Fusion
  for (j = 0; j < _PB_M; j++)
  {
    mean[j] = SCALAR_VAL(0.0);
    stddev[j] = SCALAR_VAL(0.0);
    for (i = 0; i < _PB_N; i++)
      mean[j] += data[i][j];
    mean[j] /= float_n;
    for (i = 0; i < _PB_N; i++)
      stddev[j] += (data[i][j] - mean[j]) * (data[i][j] - mean[j]);
    stddev[j] /= float_n;
    stddev[j] = SQRT_FUN(stddev[j]);
    stddev[j] = stddev[j] <= eps ? SCALAR_VAL(1.0) : stddev[j];
  }
```

```
correlation PAPI_TOT_CYC:        22516630578 / 22799808108 / 2.26586189926e10
correlation PAPI_TOT_INS:        7091744742 / 7091744790 / 7.0917447779e9
correlation PAPI_L1_DCM:         2240416310 / 2244017021 / 2.2417243094e9
correlation PAPI_L2_DCM:         3778652274 / 4035607894 / 3.9743172751e9
correlation PAPI_LST_INS:        3031677319 / 3035389922 / 3.0345817034e9
correlation PAPI_RES_STL:        19383235840 / 19606453946 / 1.94723605812e10
correlation PAPI_VEC_SP:         0 / 0 / 0.0
correlation PAPI_VEC_DP:         2023563600 / 2023563600 / 2.0235636e9
```

```
Instructions Per Cycle: 0.31495585973369516
Vector Instructions Per Cycle: 0.08986973397241478
L1 Data Cache Miss Rate: 0.7390022335025425
L2 Data Cache Miss Rate: 1.246389993525561
L1 Accesses Per Instruction: 0.42749385790005356
L1 Accesses Per Vector Instruction: 1.498187316178251
Percentage Of Cycles Stalled: 0.8608408692790164
```

And we still don't see any improvement.

### Last Tries

So far I've avoided touching the final loop nest. Since it is not a recctandular loop pattern, we need to be extra careful transforming it. So first I will perform loop fission to make it easier to work with.

```
  for (i = 0; i < _PB_M - 1; i++)
    corr[i][i] = SCALAR_VAL(1.0);

  for (i = 0; i < _PB_M - 1; i++)
    for (j = i + 1; j < _PB_M; j++)
      corr[i][j] = SCALAR_VAL(0.0);

  for (i = 0; i < _PB_M - 1; i++)
    for (j = i + 1; j < _PB_M; j++)
      for (k = 0; k < _PB_N; k++)
        corr[i][j] += (data[k][i] * data[k][j]);

  for (i = 0; i < _PB_M - 1; i++)
    for (j = i + 1; j < _PB_M; j++)
      corr[j][i] = corr[i][j];
```

Then I just permute the triple nested loop to be of ikj order since this is basically matrix multiply.

```
  for (i = 0; i < _PB_M - 1; i++)
    for (k = 0; k < _PB_N; k++)
      for (j = i + 1; j < _PB_M; j++)
        corr[i][j] += (data[k][i] * data[k][j]);
```

```
correlation PAPI_TOT_CYC:        1722815057 / 2086327726 / 1.8744406695e9
correlation PAPI_TOT_INS:        4134719976 / 4134719999 / 4.1347199847e9
correlation PAPI_L1_DCM:         134606303 / 134666473 / 1.346379922e8
correlation PAPI_L2_DCM:         282408684 / 290172625 / 2.880996756e8
correlation PAPI_LST_INS:        1555302770 / 1555541923 / 1.5554968198e9
correlation PAPI_RES_STL:        689792575 / 1217320390 / 8.490743317e8
correlation PAPI_VEC_SP:         0 / 0 / 0.0
correlation PAPI_VEC_DP:         1019807800 / 1019807800 / 1.0198078e9
```

```
Instructions Per Cycle: 2.3999790106315513
Vector Instructions Per Cycle: 0.5919427020656692
L1 Data Cache Miss Rate: 0.08654668762661562
L2 Data Cache Miss Rate: 0.18157794703856922
L1 Accesses Per Instruction: 0.37615673589209464
L1 Accesses Per Vector Instruction: 1.5250940128130026
Percentage Of Cycles Stalled: 0.40038689712937653
```

And we finally see huge improvement!

### Loop transformation results

Only the final loop transformation and permutation showed any real improvement. I'm realizing now that I compiled all the above experiments with -O3 optimizations enabled. The compiler probably made its own optimizations in such a way that none of the transformations I tried mattered except for the tricky triangular loop at the end.

# Open MP Parallelization

Since we have already tuned our code for maximum distribution. Implementing parallelization should be easy.

We throw omp pragmas over every distributed loop nest with the appropriate private() variables and we explore the number of threads from 1-8.

```
correlation_1 PAPI_TOT_CYC:      1684120903 / 2169212775 / 1.764475229e9
correlation_1 PAPI_TOT_INS:      4127606184 / 4127606205 / 4.1276061908e9
correlation_1 PAPI_L1_DCM:       134531203 / 134883336 / 1.346824096e8
correlation_1 PAPI_L2_DCM:       285675277 / 290447786 / 2.884074351e8
correlation_1 PAPI_LST_INS:      1550460381 / 1550495845 / 1.550485831e9
correlation_1 PAPI_RES_STL:      618688704 / 1040567861 / 7.559548208e8
correlation_1 PAPI_VEC_SP:       0 / 0 / 0.0
correlation_1 PAPI_VEC_DP:       1019807801 / 1019807801 / 1.019807801e9

correlation_2 PAPI_TOT_CYC:      1303002582 / 1381676361 / 1.3367542805e9
correlation_2 PAPI_TOT_INS:      3072921344 / 3073064131 / 3.0729589369e9
correlation_2 PAPI_L1_DCM:       99143751 / 99289227 / 9.92071726e7
correlation_2 PAPI_L2_DCM:       203600940 / 205280667 / 2.044961985e8
correlation_2 PAPI_LST_INS:      1153576150 / 1153610629 / 1.1535961761e9
correlation_2 PAPI_RES_STL:      563800924 / 622117902 / 5.920470491e8
correlation_2 PAPI_VEC_SP:       0 / 0 / 0.0
correlation_2 PAPI_VEC_DP:       761881501 / 761881501 / 7.61881501e8

correlation_3 PAPI_TOT_CYC:      979616711 / 1039433032 / 1.0066583713e9
correlation_3 PAPI_TOT_INS:      2272870409 / 2272966266 / 2.2729263012e9
correlation_3 PAPI_L1_DCM:       73167992 / 73257503 / 7.32119609e7
correlation_3 PAPI_L2_DCM:       147473288 / 149848227 / 1.486953268e8
correlation_3 PAPI_LST_INS:      853148031 / 853165782 / 8.531578383e8
correlation_3 PAPI_RES_STL:      428977535 / 490903425 / 4.458821167e8
correlation_3 PAPI_VEC_SP:       0 / 0 / 0.0
correlation_3 PAPI_VEC_DP:       563921001 / 563921001 / 5.63921001e8

correlation_4 PAPI_TOT_CYC:      769848937 / 788608371 / 7.774278051e8
correlation_4 PAPI_TOT_INS:      1788813247 / 1788905438 / 1.7888322493e9
correlation_4 PAPI_L1_DCM:       57537973 / 57609338 / 5.75664499e7
correlation_4 PAPI_L2_DCM:       116398145 / 116688323 / 1.165365793e8
correlation_4 PAPI_LST_INS:      671392015 / 671410522 / 6.714007294e8
correlation_4 PAPI_RES_STL:      339358079 / 357534788 / 3.464220475e8
correlation_4 PAPI_VEC_SP:       0 / 0 / 0.0
correlation_4 PAPI_VEC_DP:       443940751 / 443940751 / 4.43940751e8

correlation_5 PAPI_TOT_CYC:      624602125 / 638934729 / 6.31175466e8
correlation_5 PAPI_TOT_INS:      1471403333 / 1471442240 / 1.4714296026e9
correlation_5 PAPI_L1_DCM:       47297773 / 47337931 / 4.73159053e7
correlation_5 PAPI_L2_DCM:       95186316 / 95600050 / 9.5432892e7
correlation_5 PAPI_LST_INS:      552250164 / 552262555 / 5.522580332e8
correlation_5 PAPI_RES_STL:      274995304 / 287342524 / 2.810497562e8
correlation_5 PAPI_VEC_SP:       0 / 0 / 0.0
correlation_5 PAPI_VEC_DP:       365232601 / 365232601 / 3.65232601e8

correlation_6 PAPI_TOT_CYC:      507589330 / 524335383 / 5.15209845e8
correlation_6 PAPI_TOT_INS:      1248608557 / 1248616291 / 1.248613026e9
correlation_6 PAPI_L1_DCM:       40119217 / 40158172 / 4.01406968e7
correlation_6 PAPI_L2_DCM:       80292287 / 80714594 / 8.04714541e7
correlation_6 PAPI_LST_INS:      468620077 / 468625843 / 4.686238128e8
correlation_6 PAPI_RES_STL:      209978424 / 224489714 / 2.158345099e8
correlation_6 PAPI_VEC_SP:       0 / 0 / 0.0
correlation_6 PAPI_VEC_DP:       309960501 / 309960501 / 3.09960501e8

correlation_7 PAPI_TOT_CYC:      490086174 / 503502799 / 4.95348075e8
correlation_7 PAPI_TOT_INS:      1087264619 / 1087269470 / 1.087266979e9
correlation_7 PAPI_L1_DCM:       35901494 / 35952907 / 3.59290158e7
correlation_7 PAPI_L2_DCM:       71145753 / 71555416 / 7.1384346e7
correlation_7 PAPI_LST_INS:      408075724 / 408077116 / 4.080763441e8
correlation_7 PAPI_RES_STL:      199230605 / 208081259 / 2.039475634e8
correlation_7 PAPI_VEC_SP:       0 / 0 / 0.0
correlation_7 PAPI_VEC_DP:       269937231 / 269937231 / 2.69937231e8

correlation_8 PAPI_TOT_CYC:      444217727 / 457642929 / 4.492924449e8
correlation_8 PAPI_TOT_INS:      957448843 / 957459798 / 9.574534236e8
correlation_8 PAPI_L1_DCM:       32951479 / 33008805 / 3.29754168e7
correlation_8 PAPI_L2_DCM:       62842753 / 63158805 / 6.30335494e7
correlation_8 PAPI_LST_INS:      359348967 / 359382764 / 3.593544585e8
correlation_8 PAPI_RES_STL:      163729218 / 181340064 / 1.688527264e8
correlation_8 PAPI_VEC_SP:       0 / 0 / 0.0
correlation_8 PAPI_VEC_DP:       237720381 / 237720381 / 2.37720381e8
```

```
1 & 2.4508965933783675 & 0.6055431051199297 & 0.08676855252065935 & 0.1842519038221074 & 0.37563185824512757 & 1.5203456763908398 & 0.3673659669551646
2 & 2.3583386452568056 & 0.5847121959118267 & 0.08594469554523991 & 0.17649544852327262 & 0.3754004808005916 & 1.514114922708958 & 0.43269363529166055
3 & 2.320162961164512 & 0.5756547378865611 & 0.08576236402285033 & 0.17285779564789266 & 0.3753614933881609 & 1.5128857224453678 & 0.4379034475249984
4 & 2.3235899421654977 & 0.5766595622382472 & 0.08569951937840667 & 0.17336837853217543 & 0.3753281770056123 & 1.512345990963105 & 0.44081125879374955
5 & 2.3557450000670426 & 0.5847444098913368 & 0.08564555718266839 & 0.17236086506621662 & 0.375322083085155 & 1.5120505740395283 & 0.4402727640415889
6 & 2.459879440334177 & 0.6106521210759099 & 0.08561139176288429 & 0.17133770177755317 & 0.37531384385666994 & 1.5118703044037214 & 0.4136777737231001
7 & 2.218517225503285 & 0.5507954423541849 & 0.08797752938618814 & 0.17434448759318993 & 0.3753232808911995 & 1.51174301702754 & 0.4065215783867431
8 & 2.1553593762817123 & 0.5351438417494762 & 0.09169771455054719 & 0.17487945916371592 & 0.375319234679988 & 1.5116455959238935 & 0.36857875777658916
```

# Vectorization

Well, since I already did part one of this project with -O3 enabled, I'm going to use this section to compare against the default correlation.c implementation.

correlation.c no threads no optimization (-O0)
```
correlation PAPI_TOT_CYC:        27942334425 / 29473383644 / 2.84843647997e10
correlation PAPI_TOT_INS:        38526856891 / 38526857006 / 3.85268569441e10
correlation PAPI_L1_DCM:         2257177525 / 2259311980 / 2.258122552e9
correlation PAPI_L2_DCM:         4570310891 / 4723745915 / 4.6512183227e9
correlation PAPI_LST_INS:        20273420011 / 20274456470 / 2.0274020119e10
correlation PAPI_RES_STL:        16485611667 / 17666136855 / 1.70720545097e10
correlation PAPI_VEC_SP:         0 / 0 / 0.0
correlation PAPI_VEC_DP:         2029443600 / 2029443600 / 2.0294436e9
```

```
Instructions Per Cycle: 1.3787987898580882
Vector Instructions Per Cycle: 0.07262970835336711
L1 Data Cache Miss Rate: 0.11133679092009613
L2 Data Cache Miss Rate: 0.22543364111828346
L1 Accesses Per Instruction: 0.5262152598733258
L1 Accesses Per Vector Instruction: 9.989644457722303
Percentage Of Cycles Stalled: 0.5899869143449349
```

corellation-modified.c no threads -O3 optimizations
```
correlation PAPI_TOT_CYC:        1722815057 / 2086327726 / 1.8744406695e9
correlation PAPI_TOT_INS:        4134719976 / 4134719999 / 4.1347199847e9
correlation PAPI_L1_DCM:         134606303 / 134666473 / 1.346379922e8
correlation PAPI_L2_DCM:         282408684 / 290172625 / 2.880996756e8
correlation PAPI_LST_INS:        1555302770 / 1555541923 / 1.5554968198e9
correlation PAPI_RES_STL:        689792575 / 1217320390 / 8.490743317e8
correlation PAPI_VEC_SP:         0 / 0 / 0.0
correlation PAPI_VEC_DP:         1019807800 / 1019807800 / 1.0198078e9
```

```
Instructions Per Cycle: 2.3999790106315513
Vector Instructions Per Cycle: 0.5919427020656692
L1 Data Cache Miss Rate: 0.08654668762661562
L2 Data Cache Miss Rate: 0.18157794703856922
L1 Accesses Per Instruction: 0.37615673589209464
L1 Accesses Per Vector Instruction: 1.5250940128130026
Percentage Of Cycles Stalled: 0.40038689712937653
```