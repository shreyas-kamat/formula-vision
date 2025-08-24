# 🤝 Contributing to Formula-Vision
Welcome to Formula-Vision, a Flutter-based project for Live Data, Championship Standings, Schedules, etc for Formula One.  Whether you’re fixing bugs, improving UI, or adding new telemetry features, we appreciate your help!

### Table Of Contents
- <a href="#contributor-license-agreement">License Agreement</a>
- <a href="#how-to-contribute">How to Contribute</a>
- <a href="#development-setup">Development Setup</a>
- <a href="#commit--branch-creation-format">Commit & Branch Creation Format</a>

## Contributor License Agreement

By contributing to this project, you agree that your contributions will be licensed under the same license as the project, the Apache License 2.0.

Specifically:
- You grant us (and everyone else) a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable license to use, reproduce, prepare derivative works of, publicly display, publicly perform, sublicense, and distribute your contributions and such derivative works under the terms of the Apache License 2.0.
- You represent that you have the right to grant this license for your contributions.
- You agree to share non-exclusive copyright ownership of your contributions with the project owners.
- The project owners reserve the right to change the license of the project at their discretion. Any changes will be communicated to contributors and users through the appropriate channels.

If you do not agree to these terms, please do not submit contributions to this project.

## How to Contribute


### Did you find a bug?
* **Ensure the bug was not already reported** by searching on GitHub under [Issues](https://github.com/shreyas-kamat/formula-vision/issues).
* If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/shreyas-kamat/formula-vision/issues/new). Be sure to include a **title and clear description**, as much relevant information as possible, the endpoint returning an unexpected result alongside the expected result.

### Did you have a solution for an Issue?
* Fork the Repository
* Commit your Changes to Fork and Test the project

### Did you patch that **successfully** fixes a bug?
* Make sure your changes don't affect any other features (App is Stable)
* Make a Github [Pull Request](https://github.com/shreyas-kamat/formula-vision/pulls)
* Ensure you follow [Commit Style Guidelines](https://github.com/shreyas-kamat/formula-vision/edit/main/CONTRIBUTING.md#commit--branch-creation-format) while doing so.
* Ensure the PR description clearly describes the problem and solution. Include the relevant issue number if applicable.
* Before submitting, please read the [License](/LICENSE) and [Contributor License Agreement](#contributor-license-agreement) as by contributing and submitting a PR you agree to follow both.

### Do you intend to add a new feature or change an existing one?
* Suggest your change on GitHub under [Issues](https://github.com/jolpica/jolpica-f1/issues) before writing code, specifying what you intend to contribute.
* Make Sure you add the "Enhancement" Label while creating an Issue.
* Before submitting, please read the [License](/LICENSE) and [Contributor License Agreement](#contributor-license-agreement) as by contributing and submitting a PR you agree to follow both. 

**NOTE!: This only applies when you already have a partial/complete solution to the feature you wish to add. If you wish to request for a feature please do so, in [Feature Requests](https://github.com/shreyas-kamat/formula-vision/discussions/categories/feature-requests)**

## Development Setup

### Prerequisites
* Flutter SDK
* Git

### Initial Setup

**Clone the Repository**
```
git clone https://github.com/shreyas-kamat/formula-vision.git
```
```
cd formula-vision
```
<br/>

Create a `.env` file and add the following: 
```
API_URL=http://10.0.2.2:3000
```
NOTE: This is currently a Test URL until the API is fully functional, structured and stable   
  
<br/>

**Run the project**

```
flutter run
```
NOTE: This command will automatically install all required dependencies for the project




## Commit & Branch Creation Format

We use [Conventional Commits](https://www.conventionalcommits.org/) for our Commit Messages and Branch Creation

### Commits
An example commit message for fixing a bug in authentication would look like

```
fix(auth): Fixed Bug regarding Saving Refresh Token in Local DB
```

An example commit adding a feature giving the user a modal to select favourite driver would look like:

```
feat(ui): Added Selection Modal for Favourite Driver
```

### Branches
An example branch for a bug fix would look like:
```
fix/save-refresh-token
```

An example branch for a new feature would look like:
```
feat/favourite-driver-selection
```
  
<br/>

**Branches with Major Feature Updates**  
Any Branches created for Major Feature Updates (Breaking Changes) will just have a simple branch name and will not follow above procedure.   

  
For Example, for adding a feature like Live Data Fetching which will require an API a branch would look like:
```
live-data
```






