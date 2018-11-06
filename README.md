
Matlab scripts and function to work with iEEG files.

 * File conversion 
     * NSX (Blackrock) to EDF 
     * NCS (Neuralynx) to EDF
 * Change the montage (monopolar to bipolar, inter/intra tetrode montage)
 * Synchronize micro- and Macro- files
 * Automated EpiFaR files conversion  

The main scripts are described here :

|      Function       |              file                     |              misc.                      |
|:-------------------:|:-------------------------------------:|-----------------------------------------|
| `Format Conversion`   |     *fileconv_nsx2edf()*              |                                         |
|                     |     *nsx2eeglab()*                    |                                         |
|                     |     *dirconv_nsx2edf*                 |                                         |
| `Mono-to-bipolar`     |     *fileconv_mono2bipolar_macro()*   |                                         |
|                     |     *fileconv_mono2bipolar_micro()*   |                                         |
|                     |     *mono2bipolar_macro()*            |                                         |
|                     |     *mono2bipolar_micro()*            |                                         |
|                     |     *dirconv_mono2bipolar_macro*      |                                         |
|                     |     *dirconv_mono2bipolar_micro*      |                                         |
| `Synchronization`     |     *filesync_macromicro()*           |                                         |
| `Divide`             |     *filedivide_edf()*                |                                         |
| `EpiFaR`              |     *jediconv*                        |                                         |
|                     |     *jediconv_dir*                    |                                         |
|                     |     *yodaconv*                        |         Experimental                    |


External files needed : 

 * For Blackrock files (*ns5*, *nsx*, *nev*), download the [NPMK toolbox](https://github.com/BlackrockMicrosystems/NPMK)
 * For NeuraLynx files (*ncs*), you will need the NeuraLynx [*MATLAB Import/Export MEX Files*](https://neuralynx.com/software/category/matlab-netcom-utilities)
 * EEGLAB is needed for most of the scripts 
 * ERPLAB is needed for the monopolar to bipolar conversion scripts