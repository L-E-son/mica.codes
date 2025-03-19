var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.mica_codes>("mica-codes");

builder.Build().Run();
