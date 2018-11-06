
Matlab scripts and function to work with iEEG files.

 * File conversion 
     * NSX (Blackrock) to EDF 
     * NCS (Neuralynx) to EDF
 * Change the montage (monopolar to bipolar, inter/intra tetrode montage)
 * Synchronize micro- and Macro- files
 * Automated EpiFaR files conversion  

The main scripts are described here :

|      Function       |              file                     |         misc.     |     Down-sampling   |
|:-------------------:|:-------------------------------------:|:-----------------:|:-------------------:|
| `Format Conversion` |     *fileconv_nsx2edf()*              |                   |          Yes        |
|                     |     *nsx2eeglab()*                    |                   |          Yes        |
|                     |     *dirconv_nsx2edf*                 |                   |          Yes        |
| `Mono-to-bipolar`   |     *fileconv_mono2bipolar_macro()*   |                   |          No         |
|                     |     *fileconv_mono2bipolar_micro()*   |                   |          No         |
|                     |     *mono2bipolar_macro()*            |                   |          No         |
|                     |     *mono2bipolar_micro()*            |                   |          No         |
|                     |     *dirconv_mono2bipolar_macro*      |                   |          No         |
|                     |     *dirconv_mono2bipolar_micro*      |                   |          No         |
| `Synchronization`   |     *filesync_macromicro()*           |                   |          No         |
| `Divide`            |     *filedivide_edf()*                |                   |          No         |
| `Downsampling`      |     *fileconv_downsample_edf()*       |                   |          Yes        |
|                     |     *dirconv_downsample_edf*          |                   |          Yes        |
| `EpiFaR`            |     *jediconv*                        |                   |          Yes        |
|                     |     *jediconv_dir*                    |                   |          Yes        |
|                     |     *yodaconv*                        |     Experimental  |          Yes        |


External files needed : 

 * For Blackrock files (*ns5*, *nsx*, *nev*), download the [NPMK toolbox](https://github.com/BlackrockMicrosystems/NPMK)
 * For NeuraLynx files (*ncs*), you will need the NeuraLynx [*MATLAB Import/Export MEX Files*](https://neuralynx.com/software/category/matlab-netcom-utilities)
 * EEGLAB is needed for most of the scripts 
 * ERPLAB is needed for the monopolar to bipolar conversion scripts
