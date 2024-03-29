﻿using System;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace ProspaAspNetCoreApi.Controllers.V1
{
    [Route("[controller]")]
    [ApiExplorerSettings(IgnoreApi = true)]
    [ApiController]
    [ApiVersionNeutral]
    public class DocsController : ControllerBase
    {
        private readonly IHostingEnvironment _hostingEnvironment;

        public DocsController(IHostingEnvironment hostingEnvironment)
        {
            _hostingEnvironment = hostingEnvironment ?? throw new ArgumentNullException(nameof(hostingEnvironment));
        }

        [HttpGet]
        public Task Docs(string endpointKey)
        {
            var docs = System.IO.File.ReadAllText(_hostingEnvironment.ContentRootPath + "/docs.json");

            return Response.WriteAsync(docs, Encoding.UTF8);
        }
    }
}