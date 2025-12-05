# Analysis Pipeline for Ferret Visual Cortex (vhlab-tpdirection)

A MATLAB-based analysis toolbox developed for the Van Hooser Lab to analyze direction, spatial frequency, and temporal frequency tuning in 2-photon calcium imaging data.

## System Architecture

```mermaid
graph TD
    %% Define Styles
    classDef raw fill:#f9f,stroke:#333,stroke-width:2px;
    classDef process fill:#e1f5fe,stroke:#0277bd,stroke-width:2px;
    classDef storage fill:#fff9c4,stroke:#fbc02d,stroke-width:2px;
    classDef viz fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;

    subgraph "Phase 1: Preprocessing"
        RawData[("Raw 2-Photon Data")]:::raw --> TPL[twophotonbulkload]:::process
        TPL -->|Cell Drawing & ROI| StackFile[".stack File"]:::storage
    end

    subgraph "Phase 2: Data Ingestion (NDI)"
        StackFile -->|stack2ndi| NDI[NDI Session]:::storage
        NDI -->|ndi.session.dir| Elements[ROI Elements]:::storage
    end

    subgraph "Phase 3: Core Analysis"
        Elements -->|combinedTuningCurve| TC_Doc[Tuning Curve Doc]:::storage
        TC_Doc -->|sigDirSFTF| SigTest{Significant?}:::process
        TC_Doc -->|dirVector| Metrics["Metrics Calculation:<br/>- Direction Index (DI)<br/>- Preferred Direction<br/>- Vector Sum"]:::process
    end

    subgraph "Phase 4: Visualization"
        Metrics -->|dirMap| SpatialMap[Direction Selectivity Map]:::viz
        SigTest -- Yes -->|plotAll| PopPlot[Population Tuning Surfaces]:::viz
        SigTest -- Yes -->|plotDirTF_bestSF| SinglePlot[Single Cell Surface]:::viz
    end
