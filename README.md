# SV-Plaudit

A pipeline for creating image views of genomic intervals, automatically storing them in the cloud, deploying a website to view/score them, and retrieving scores for analysis.

The PlotCritic and Samplot submodules each contain instructions for use. `upload.py` is the meeting point between them and handles uploading images created by Samplot to cloud storage managed by PlotCritic.

Usage:
1. Generate a set of images with Samplot.
2. Follow PlotCritic setup instructions to create the cloud environment.
3. Run `upload.py` with the directory that holds the Samplot images to upload them.
    ```
    python upload.py -d your_directory
    ```
4. Follow PlotCritic instructions to score images and retrieve scores.
